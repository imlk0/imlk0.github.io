---
title: "理解MindSpore Lite计算图与自定义算子"
date: 2022-09-25T09:08:24+08:00
categories:
  - ML
tags:
  - MindSpore
  - ML
draft: false
---


# MindSpore 模型格式

- [`converter_lite`](https://www.mindspore.cn/lite/docs/zh-CN/r1.8/use/converter_tool.html)工具
    - 支持的输入格式：MINDIR(MindSpore `.mindir`)、CAFFE、TFLITE、TF、ONNX
    - 输出格式MINDIR_LITE(`.ms`)
- MINDIR(`.mindir`)
    - MindSpore的模型文件，protobuff格式
- MINDIR_LITE(`.ms`)
    - 目前是`MSL2`版本，flatbuffer序列化文件，可推理，可训练。旧版为`MSL0`版本
    - [schema文件](https://github.com/mindspore-ai/mindspore/blob/d351abb9f16a337610400ef5eba7af58bf291fb3/mindspore/lite/schema/model.fbs#L22)

    - MindIR
        - IR的定义https://www.mindspore.cn/docs/zh-CN/r0.7/design/mindspore/ir.html
        - 对应Lite算子https://www.mindspore.cn/lite/docs/zh-CN/r1.8/operator_list_lite.html

# MindSpore计算图结构

- SubGraph：模型是由相互嵌套的多个SubGraph组成的
- Tensor：神经元，表示各层的输入输出，权重
- Primitive：Mindspore定义的一种IR的算子
- CNode：表示图上的一个算子行为，包含了：输入输出的tensor，由Primitive表示的具体的算子类型
    - 注意，mindspore的算子的输入输出可以有多个
    - 注意，其中的device_type字段几乎可以忽略，目前仅两个用途。1. 仅在GPU的优先级高于CPU且该字段设置为GPU时，该节点才会选择使用GPU的Kernel。2. 仅在开启了[模型并行策略时才会影响](https://www.mindspore.cn/lite/docs/zh-CN/r1.8/use/runtime_cpp.html#%E9%85%8D%E7%BD%AE%E5%B9%B6%E8%A1%8C%E7%AD%96%E7%95%A5)SetEnableParallel
- PartialFusion：一个特殊的算子，表示一个子图包含了一个SubGraph的索引号

# MindSpore模型初始化流程

1. `LiteModel::ConstructModel()` 从flatbuffers创建LiteModel对象。
    1. `LiteModel::ConvertNodes()` 从flatbuffers初始化`mindspore::lite::LiteGraph::Node`对象
    2. `LiteModel::ConvertTensors()` 从flatbuffers初始化`mindspore::schema::Tensor`对象
2. `LiteSession::CompileGraph(Model *model)`
    1. `LiteSession::ConvertTensors()` 根据模型中定义的`mindspore::schema::Tensor`对象实例化成`mindspore::lite::Tensor`对象
    2. `Scheduler::Schedule(std::vector<kernel::KernelExec *> *dst_kernels)` 实例化`mindspore::kernel::KernelExec`对象
        1. `Scheduler::ScheduleGraphToKernels()` 将图转换成KernelExec对象
        2. 进行拓扑排序、将连续的Kernel按照arch类型合并成SubGraph

# MindSpore的扩展

1. [自定义运行时算子——通用算子](https://www.mindspore.cn/lite/docs/zh-CN/r1.8/use/register_kernel.html#%E9%80%9A%E7%94%A8%E7%AE%97%E5%AD%90)：对Primitive列表中，已有算子（如Add）实现的重写
2. [自定义运行时算子——Custom算子](https://www.mindspore.cn/lite/docs/zh-CN/r1.8/use/register_kernel.html#custom%E7%AE%97%E5%AD%90)：定义一种新的算子，使用Primitive列表中的Primitive::Custom算子接口，构建专属的实现。其中type和attr是可以自定义的属性
   
   ```
   table Custom {
        type: string;
        attr: [Attribute];
   }
   ```
   
3. [模型Delegate](https://www.mindspore.cn/lite/docs/zh-CN/r1.8/use/delegate.html) 提供将模型中的一部分子图卸载到别的框架执行的能力
4. [模型转换中定义算子](https://www.mindspore.cn/lite/docs/zh-CN/r1.8/use/converter_register.html#%E6%A8%A1%E5%9E%8B%E6%89%A9%E5%B1%95) converter工具提供了一种称为「图优化扩展」的能力（实际上是实现一个自定义的Pass），可以在获得MindSpore定义的图结构的基础上，对图进行修改，可将部分节点转换成Custom算子。
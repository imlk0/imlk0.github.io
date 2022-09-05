---
title: "Proxmox服务器的Grafana看板简易配置"
date: 2022-09-04T14:36:09+08:00
categories:
  - Misc
tags:
  - Proxmox
  - Grafana
  - InfluxDB
draft: false
---

ITX拿来做PVE服务器已经用了好几个月的时间了，体验还是相当不错的，但是缺乏一个直观的性能看板。早听说PVE的Metric Server特性可以用来监视性能，恰逢最近有看到有人推Grafana，因此准备来体验一下。

# 前奏

首先参考一下PVE的官方[文档](https://pve.proxmox.com/wiki/External_Metric_Server#metric_server_influxdb)关于Metric Server的描述。

别看这文档虽然短小，但也潜藏着不少坑。由于我们的实验是以InfluxDB V2版本进行。首先文档中的配置文件内容是针对InfluxDB V1的，在InfluxDB V2中不再适用。且文档建议使用UDP连接InfluxDB，但是InfluxDB V2中默认已经是http了。幸运的是这文档里对V2的配置提了一嘴。

# 配置InfluxDB

那么我们创建一个lxc容器部署我们的InfluxDB服务和Grafana服务。

在lxc容器里装好influxdb和influx-cli并启动influxdb
```sh
systemctl enable --now influxdb
```
启动后默认监听http端口是`8086`，WebUI和API接口都在这个端口上访问

首次启动需要进行Setup，可以从WebUI上Setup，也可以在CLI工具上Setup。可以参考influxdb的[文档](https://docs.influxdata.com/influxdb/v2.4/install/?t=Linux#set-up-influxdb)


这里我们用CLI工具进行setup。

```sh
influx setup
```
这是一个交互式的过程，我们设置一个名为`proxmox`的organization和一个名为`proxmox`的bucket/database。

# 配置PVE侧Metric Server

在proxmox上配置(Datacenter -> Metric Server -> Add -> InfluxDB)：

要获得token，运行：
```
influx config list --json
```
![](/images/proxmox-influxdb-01.png)


# 配置Grafana

安装并启动Grafana
```sh
systemctl enable --now grafana
```

访问WebUI，默认端口是3000

## 添加InfluxDB作为数据源

接下来连接InfluxDB，在WebUI上选择`Add data source`。

Query Language选择`Flux`，填写InfluxDB的URL。

![](/images/proxmox-grafana-01.png)

关掉Basic auth，剩余的Organization和Default Bucket填`proxmox`，Token填你的token

![](/images/proxmox-grafana-02.png)

## 设置Proxmox Dashboard

接着Import [这个](https://grafana.com/grafana/dashboards/15356-proxmox-flux/)ID为`15356`的dashboard就可以了

记得顶上的Bucket选`proxmox`不然是No Data。

![](/images/proxmox-grafana-03.png)


---
title: "Spectre Meltdown and Defenses"
date: 2021-11-24T09:33:17+08:00
draft: true
---


# Attacks

## Meltdown

## Spectre


# Defenses

## Speculative Load Hardening

https://llvm.org/docs/SpeculativeLoadHardening.html


```c++
uintptr_t all_ones_mask = std::numerical_limits<uintptr_t>::max();
uintptr_t all_zeros_mask = 0;
void leak(int data);
void example(int* pointer1, int* pointer2) {
  uintptr_t predicate_state = all_ones_mask;
  if (condition) {
    // Assuming ?: is implemented using branchless logic...
    predicate_state = !condition ? all_zeros_mask : predicate_state;
    // ... lots of code ...
    //
    // Harden the pointer so it can't be loaded
    pointer1 &= predicate_state;
    leak(*pointer1);
  } else {
    predicate_state = condition ? all_zeros_mask : predicate_state;
    // ... more code ...
    //
    // Alternative: Harden the loaded value
    int value2 = *pointer2 & predicate_state;
    leak(value2);
  }
}
```
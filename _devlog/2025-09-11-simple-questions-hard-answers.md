---
layout: post
title: "Is not feasible for function types to be instances Eq"
date: 2025-09-11
---

 
Exercise 5 in set 3.11 in "Programming in Haskell" book asked:

> Why is not feasible in general for function types to be instances of `Eq` class?

The answer was not as easy as I thought. Everything revolves around the problem of computing
the equality of two functions, which is an **undecidable** problem. 
The mathematical definition of function equality (extensional equality) requires that 
f == g if and only if f(x) == g(x) for all possible inputs x. 
While this definition is mathematically correct, implementing it computably is undecidable, 
meaning that we cannot write an algorithm that reliably determines whether two arbitrary functions are extensionally equal.
Consider an infinite domain like `Int -> Int`. You won't be able to test it for each possible input.


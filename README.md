# Dito

Dito.jl is a package for **Di**fferentiable **T**rajetory **O**ptimization in Julia. It supports both forward and reverse mode differentiation via [ForwardDiff.jl](https://github.com/JuliaDiff/ForwardDiff.jl) and [ChainRulesCore.jl](https://github.com/JuliaDiff/ChainRulesCore.jl) and therefore integrates seamlessly with machine learning frameworks such as [Flux.jl](https://github.com/FluxML/Flux.jl).

---

A substantial part of machine learning (ML) algorithms relies upon the ability to propagate gradient signals through the entire learning pipeline.
Traditionally, such models have been mostly limited to artificial neural networks and "simple" analytic functions.
Recent work has focused on extending the class of admissible models for gradient-based learning by making all sorts of procedures differentiable.
These efforts range from [differentiable physics simulators]() over [differentiable rendering]() to [differentiable optimzation]().

Dito.jl focus on a special case of the latter category, differentiable trajectory optimization.
As such, Dito algorithmically provides a (local) answer to the question:

> *"How does the optimal solution of an inequality constrained trajectory optimization problem change if the problem changes?"*.

This implementation was initially developed as part of our research on [Learning Mixed Strategies in Trajectory Games](https://arxiv.org/pdf/2205.00291.pdf).
There, Dito allowed us to efficiently train a neural network pipeline that rapidly generates feasible equilibrium trajectories in multi-player non-cooperative dynamic games.
Since this component has proven to be very useful in that context, we have since decided to factor it out into a stand-alone package.

## Installation

To install Dito, imply add it via Julia's package manage from the REPL:

```julia
pkg> add Dito
```
## Usage

- TODO: Setting up a `ParametricOptimizationProblem`
- TODO: Solving the problem using different backends

## Background

- TODO: Mainly just punt to the literature on this. TL;DR: Rather than differentiating the entire (potentially iterative) forward procedure, exploit the [IFT](https://en.wikipedia.org/wiki/Implicit_function_theorem).

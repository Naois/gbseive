# gbseive

This project implements a seiving solution to [Project Euler problem 7](https://projecteuler.net/problem=7) on the Gameboy. In the process of implementing this, I also created a rudimentary system for converting images to tile data.

To build this, you will need to install [rgbds](https://rgbds.gbdev.io/) (I did this through msys2) and ensure that the binaries folder listed in the Makefile is correct. Then just run make.

The implementation is able to seive all of the odd primes up to around 120000 by representing each odd number by a bit in WRAM.

If you want to run it yourself, I would recommend building it and running in [bgb](https://bgb.bircd.org/) so you can see what's going on in the background as it runs. In particular, viewing WRAM during the seiving process is entertaining.

Coding this was a great learning experience, and I would highly recommend a similar project to anyone who would like to learn assembly programming.
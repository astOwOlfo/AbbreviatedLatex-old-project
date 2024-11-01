This as a proof of concept version of a program that transpiles documents written containing mathematical formulas written in a consize and visually readable format into LaTeX.

Examples in the `test1.atx`, `test2.atx`, `test3.atx` files, which are transpiled to `test1.tex`, `test2.tex`, `test3.tex`.

```
USAGE : julia atx.jl <input.atx> <output.tex>
Use the '-d' or '--dynamic' flag to update output.tex each time input.tex is changed.
Use the '-p' or '--pdf' flag to execute 'pdflatex <output.tex>' after updating output.tex.
```

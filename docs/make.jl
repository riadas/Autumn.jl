using Documenter
using Autumn

makedocs(
  modules = [Autumn],
  authors = "Zenna Tavares, Ria Das",
  format = Documenter.HTML(),
  sitename = "Autumn.jl",
  pages = [
    "Home" => "index.md",
    "Tutorial" => "tutorial.md",
    "Language" => "lang.md"
  ]
)

deploydocs(
  repo = "github.com/riadas/Autumn.jl.git",
)

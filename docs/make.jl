using Documenter
using Omega

makedocs(
  modules = [Omega],
  authors = "Zenna Tavares, Ria Das",
  format = Documenter.HTML(),
  sitename = "Omega.jl",
  pages = [
    "Home" => "index.md",
    "Tutorial" => "tutorial.md",
    "Language" => "lang.md"
  ]
)

deploydocs(
  repo = "github.com/riadas/Autumn.jl.git",
)

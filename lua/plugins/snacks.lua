return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            layout = {
              preset = "sidebar",
              preview = false,
              layout = {
                width = 25,
                min_width = 25,
              },
            },
          },
        },
      },
      styles = {
        terminal = {
          height = 0.2,
        },
      },
    },
  },
}

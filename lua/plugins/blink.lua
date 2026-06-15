return {
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.keymap = opts.keymap or {}
      opts.keymap["<Tab>"] = {
        function(cmp)
          if cmp.is_menu_visible() then
            return cmp.select_and_accept()
          end
        end,
        "fallback",
      }
    end,
  },
}

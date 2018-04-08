function cheatsheet()

    if web then web:delete() web=nil end
    web = hs.webview.new(hs.geometry.rect(100, 100, 600, 600))
    web:show()web:url({URL='https://gist.github.com/MohamedAlaa/2961058'})

end
hs.hotkey.bind({"cmd","alt","ctrl"}, "c", cheatsheet)

for m in module.parent.children
  path = m.id.split "/"
  name = path[path.length-1]
  if name == "coffee-script.js"
    CoffeeScript = m.exports
    break

CoffeeScript.on 'failure', (ex, task) ->
  console.log("\x21[31m#{ex.message}\x21[0m")
  require('child_process').exec('growlnotify --appIcon Terminal coffee -m "compilation failed"')


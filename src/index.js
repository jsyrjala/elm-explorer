import './main.css'
import { Elm } from './Main.elm'
import registerServiceWorker from './registerServiceWorker'
import { graph } from './graph/graph'

const initElm = (config) => {
  const app = Elm.Main.init({
    node: document.getElementById('root'),
    flags: {config: config}
  })
  // https://guide.elm-lang.org/interop/ports.html
  // See Main.elm, port graph
  if (app.ports) {
    console.info('Subscribing to Elm ports')
    app.ports.graph.subscribe(data => {
      graph(data)
    })
  } else {
    console.warn('No ports defined. Ports exists only if there is some code ' +
      'using them on Elm side')
  }
}

fetch('nflow-explorer-config.json')
  .then(result => {
    if (!result.ok) {
      console.error("Can't fetch nflow-explorer-config.json")
      return
    }
    return result.json()
      .then(json => initElm(json))
  })
  .catch(err => {
    console.error("Can't load Elm app", err)
  })

// registerServiceWorker();

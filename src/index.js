import './main.css';
import { Elm } from './Main.elm';
import registerServiceWorker from './registerServiceWorker';

const initElm = (config) => {
  Elm.Main.init({
    node: document.getElementById('root'),
    flags: {config: config}
  });

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
    console.error("Can't fetch nflow-explorer-config.json", err)
  })

registerServiceWorker();

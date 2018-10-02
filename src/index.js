import './main.css'
import { Elm } from './Main.elm'
import { drawWorkflowDefinition, markStateSelected, workflowDefinitionGraph } from './graph/workflowGraphs'

const drawInstanceGraph = (definition, workflow, stateSelectedPort) => {
  const graph = workflowDefinitionGraph(definition, workflow)
  const stateSelectedCallback = (state) => {
    stateSelectedPort.send(state)
    markStateSelected(graph, state, true)
  }
  // call DOM manipulation inside RAF, this way Elm code should be finished with the view rendering
  // e.g setTimeout won't work here
  window.requestAnimationFrame(() => {
    drawWorkflowDefinition(graph, '#instance-graph', stateSelectedCallback)
  })
}

const initElm = (config) => {
  const app = Elm.Main.init({
    node: document.getElementById('root'),
    flags: {config: config}
  })

  // https://guide.elm-lang.org/interop/ports.html
  console.info('Subscribing to Elm ports', app.ports)
  app.ports.drawInstanceGraph.subscribe(data => {
    // TODO use one port for several message types?
    // TODO read definition etc from data
    const definition = {"type":"creditDecision","onError":"manualDecision","states":[{"id":"internalBlacklist","type":"start","description":"Reject internally blacklisted customers","transitions":["decisionEngine"]},{"id":"decisionEngine","type":"normal","description":"Check if application ok for decision engine","transitions":["satQuery"]},{"id":"satQuery","type":"normal","description":"Query customer credit rating from SAT","transitions":["approved","rejected"]},{"id":"manualDecision","type":"manual","description":"Manually approve or reject the application"},{"id":"approved","type":"end","description":"Credit Decision Approved"},{"id":"rejected","type":"end","description":"Credit Decision Rejected"}],"settings":{"transitionDelaysInMilliseconds":{"immediate":0,"waitShort":30000,"minErrorWait":60000,"maxErrorWait":86400000},"maxRetries":17}}
    const workflow = undefined
    drawInstanceGraph(definition, workflow, app.ports.instanceStateSelectedIn)
  })
}

// Entry point for the program
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

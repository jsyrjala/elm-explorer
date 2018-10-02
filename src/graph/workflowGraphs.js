import dagreD3 from 'dagre-d3'
import * as d3 from 'd3'
import * as _ from 'lodash'
import embedCSS from './graph.css'


const nodeDomId = (nodeId) => {
  return 'node_' + nodeId
}

const edgeDomId = (srcNodeId, trgNodeId) => {
  return 'edge-' + srcNodeId + '-' + trgNodeId
}

export const setNodeSelected = (graph, nodeId, isTrue) => {
  const setSelected = (selector) => {
    d3.select(selector).classed('selected', isTrue)
  }
  _.each(graph.nodeEdges(nodeId), (edge) => {
    setSelected('#' + edgeDomId(edge.v, edge.w))
  })
  setSelected('#' + nodeDomId(nodeId))
}

export const markStateSelected = (graph, nodeId, selected) => {
  _.each(graph.nodes(), (node) => {
    setNodeSelected(graph, node, false)
  })
  setNodeSelected(graph, nodeId, selected)
}

export const markCurrentState = (workflow) => {
  d3.select('#' + nodeDomId(workflow.state)).classed('current-state', true)
}

export const downloadDataUrl = (dataurl, filename) => {
  const a = document.createElement('a')
  // http://stackoverflow.com/questions/12112844/how-to-detect-support-for-the-html5-download-attribute
  // TODO firefox supports download attr, but due security doesn't work in our case
  if('download' in a) {
    console.debug('Download via a.href,a.download')
    a.download = filename
    a.href = dataurl
    a.click()
  } else {
    console.debug('Download via location.href')
    // http://stackoverflow.com/questions/12676649/javascript-programmatically-trigger-file-download-in-firefox
    location.href = dataurl
  }
}

export const downloadImage = (size, dataurl, filename, contentType) => {
  console.info('Downloading image', filename, contentType)
  const canvas = document.createElement('canvas')

  const context = canvas.getContext('2d')
  canvas.width = size[0]
  canvas.height = size[1]
  const image = new Image()
  image.width = canvas.width
  image.height = canvas.height
  image.onload = function() {
    // image load is async, must use callback
    context.drawImage(image, 0, 0, this.width, this.height)
    const canvasdata = canvas.toDataURL(contentType)
    downloadDataUrl(canvasdata, filename)
  }
  image.onerror = (error) => {
    console.error('Image downloading failed', error)
  }
  image.src = dataurl
}

export const workflowDefinitionGraph = (definition, workflow) => {

  const addNodes = () => {

    const addNodesThatArePresentInWorkflowDefinition = () => {
      _.forEach(definition.states, (state) => {
        g.setNode(state.id, createNodeAttributes(state, workflow))
      })
    }

    const addNodesThatAreNotPresentInWorkflowDefinition = () => {
      //workflow && workflow.actions.push({id: 999999, state: 'dummy'}) // for testing
      (_.result(workflow, 'actions') || [])
        .filter((action) => {
          return !g.hasNode(action.state)
        })
        .forEach((action) => {
          g.setNode(action.state, createNodeAttributes({id: action.state}, workflow))
        })
    }

    const createNodeAttributes = (state, workflow) => {

      const resolveStyleClass = () => {
        let cssClass = 'node-' + (_.includes(['start', 'manual', 'end', 'error'], state.type) ? state.type : 'normal')
        if (workflow && isPassiveNode()) {
          cssClass += ' node-passive'
        }
        return cssClass

        const isPassiveNode = () => {
          return workflow.state !== state.id && _.isUndefined(_.find(workflow.actions, (action) => {
            return action.state === state.id
          }))
        }
      }

      /**
       * Count how many times this state has been retried. Including non-consecutive retries.
       */
      const calculateRetries = () => {
        return _.reduce(_.result(workflow, 'actions'), (acc, action) => {
          return action.state === state.id && action.retryNo > 0 ? acc+1 : acc
        }, 0)
      }

      return {
        rx: 5,
        ry: 5,
        class: resolveStyleClass(),
        retries: calculateRetries(),
        state: state,
        label: state.id,
        id: nodeDomId(state.id),
        shape: 'rect'
      }
    }

    addNodesThatArePresentInWorkflowDefinition()
    addNodesThatAreNotPresentInWorkflowDefinition()
  }

  const addEdges = () => {

    const setEdge = (state, transition, style) => {
      g.setEdge(state, transition, {
        id: edgeDomId(state, transition),
        class: 'edge-' + style,
        arrowheadClass: 'arrowhead-' + style,
        curve: d3.curveBasis
      })
    }

    const addEdgesThatArePresentInWorkflowDefinition = () => {
      _.forEach(definition.states, (state) => {
        _.forEach(state.transitions, (transition) => {
          setEdge(state.id, transition, 'normal')
        })
        const failureState = state.onFailure || definition.onError
        if (state.type !== 'end' && failureState !== state.id) {
          setEdge(state.id, failureState, 'error')
        }
      })
    }

    const addEdgesThatAreNotPresentInWorkflowDefinition = () => {
      let sourceState = null
      const actions = workflow.actions.slice().reverse()
      actions.push({state: workflow.state})
      _.each(actions, (action) => {
        if (sourceState && sourceState !== action.state) {
          if (!g.hasEdge(sourceState, action.state)) {
            setEdge(sourceState, action.state, 'unexpected')
          } else {
            const edgeAttributes = g.edge(sourceState, action.state)
            edgeAttributes.class = edgeAttributes.class + ' active'
          }
        }
        sourceState = action.state
      })
    }

    addEdgesThatArePresentInWorkflowDefinition()
    if (workflow) {
      addEdgesThatAreNotPresentInWorkflowDefinition()
    }

  }

  const g = new dagreD3.graphlib.Graph().setGraph({})
  // NOTE: all nodes must be added to graph before edges
  addNodes()
  addEdges()
  return g
}

export const drawWorkflowDefinition = (graph, canvasSelector, nodeSelectedCallBack) => {

  const initSvg = (canvasSelector, embedCSS) => {
    const svgRoot = d3.select(canvasSelector)
    svgRoot.selectAll('*').remove()
    svgRoot.append('style').attr('type', 'text/css').text(embedCSS)
    svgRoot.classed('svg-content-responsive', true)

    svgRoot.append('rect')
      .attr('class', 'graph-background')
      .attr('width', '100%')
      .attr('height', '100%')
      .on('click', () => nodeSelectedCallBack(null))

    return svgRoot
  }

  const decorateNodes = (canvasSelector, g, nodeSelectedCallBack) => {

    const drawRetryIndicator = () => {
      // fetch sizes for node rects => needed for calculating right edge for rect
      const nodeCoords = {}
      nodes.selectAll('rect').each(function (nodeName) {
        const t = d3.select(this)
        nodeCoords[nodeName] = {x: t.attr('x'), y: t.attr('y')}
      })

      // orange ellipse with retry count
      const retryGroup = nodes.append('g')
      retryGroup.each(function (nodeId) {
        const node = g.node(nodeId)
        if (node.retries > 0) {
          const c = nodeCoords[nodeId]
          const t = d3.select(this)
          t.attr('transform', 'translate(' + (- c.x) + ',-4)')
          t.append('ellipse')
            .attr('cx', 10).attr('cy', -5)
            .attr('rx', 20).attr('ry', 10)
            .attr('class', 'retry-indicator')
          t.append('text').append('tspan').text(node.retries)
          t.append('title').text('State was retried ' + node.retries + ' times.')
        }
      })
    }

    const buildTitle = (state) => {
      return _.capitalize(state.type) + ' state\n' + state.description
    }

    // note: always operate on the first canvas, as there can be two present in DOM
    // simultaneously during UI state transitions
    const nodes = d3.select(canvasSelector).selectAll('.nodes > g')
    nodes.append('title').text((nodeId) => buildTitle(g.node(nodeId).state))
    nodes.attr('id', (nodeId) => nodeDomId(nodeId))
    nodes.attr('class', (nodeId) => g.node(nodeId)['class'])
    nodes.on('click', (nodeId) => nodeSelectedCallBack(nodeId))
    drawRetryIndicator()
  }

  const setupAndApplyZoom = (graph, svgRoot, svgGroup) => {
    const zoom = d3.zoom().on('zoom', () => {
      svgGroup.attr('transform', d3.event.transform)
    })
    svgRoot.call(zoom)
    const aspectRatio = graph.graph().height / graph.graph().width

    console.log(aspectRatio, graph.graph().height)
    const availableWidth = parseInt(svgRoot.style('width').replace(/px/, ''))
    svgRoot.attr('height', Math.max(Math.min(availableWidth * aspectRatio, graph.graph().width * aspectRatio) + 60, 300))
    const zoomScale = Math.min(availableWidth / (graph.graph().width + 70), 1)
    svgRoot.call(zoom.transform, d3.zoomIdentity.scale(zoomScale).translate(35, 30))
  }

  const svgRoot = initSvg(canvasSelector, embedCSS)
  svgRoot.attr('preserveAspectRatio', 'xMinYMin meet')
  const svgGroup = svgRoot.append('g')
  const render = new dagreD3.render()
  render(svgGroup, graph)
  decorateNodes(canvasSelector, graph, nodeSelectedCallBack)
  setupAndApplyZoom(graph, svgRoot, svgGroup)
}

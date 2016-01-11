'use strict';
/* globals window, $, d3 */

const _ = require('lodash');
const remote = require('remote');
const frame = remote.getGlobal('frame');

let data = [
  {
    label: '/Users',
    x: 0, y: 0,
    width: 100,
    height: 80,
    score: 76,
  }, {
    label: '/Users/Guest',
    x: 75, y: 0,
    width: 25,
    height: 80,
    score: 19,
  }, {
    label: '/Users/lawrencejones',
    x: 0, y: 0,
    width: 75,
    height: 80,
    score: 57,
  }, {
    label: '/etc',
    x: 100, y: 0,
    width: 30,
    height: 50,
    score: 14,
  }, {
    label: '/Applications',
    x: 100, y: 50,
    width: 30,
    height: 30,
    score: 8,
  }
];

const processFrames = (frames) => {
  let maxWidth = _.max(frames.map((f) => { return f.x + f.width }));
  let maxHeight = _.max(frames.map((f) => { return f.y + f.height }));
  let totalVolume = maxWidth * maxHeight;

  return {
    maxWidth, maxHeight, totalVolume,
    frames: _.each(frames, (f, i) => {
      _.extend(f, {
        index: i,
        pathDepth: f.label.split('/').length,
        score: f.score || 100 * (f.width * f.height) / totalVolume,
        parent: _.find(frames, (_f) => {
          return f !== _f && f.label.lastIndexOf(_f.label) === 0
        }),
      });
    }),
  };
}

const defaultGraphOptions = () => {
  return {
    framePadding: 1,  // padding between frame rects
    textPadding: { top: 0, bottom: 0, left: 3, right: 3 },  // text label padding
    colorScale: d3.scale.category20b(),  // color scale for chart colors
  };
};

const renderGraph = (svgContainerId, unprocessedFrames, options) => {
  if (!options) { options = defaultGraphOptions(); }

  let data = processFrames(unprocessedFrames);
  let frames = data.frames;
  let svgContainer = d3.select(`#${svgContainerId}`);

  let updatePath = (($path) => {
    let template = _.template(`
      <% _.forEach(subdirs, function(subdir) { %>
        <li style="font-family: monospace"><%- subdir %></li>
      <% }); %>
      <span class="badge pull-right">
        <%- score %>
      </span>
    `);

    return (d) => {
      $path.html(template({ subdirs: d.label.split('/'), score: d.score }));
    };
  })($('<ol class="breadcrumb"><li/></ol>').appendTo(`#${svgContainerId}`))

  let parentFrameSelector = (d) => {
    let ids = [];
    do {
      ids.push(`#${svgContainerId}FrameRect-${d.index}`)
    } while ((d = d.parent));

    return ids.join(', ');
  }

  let chart = svgContainer
    .append('svg')
    .attr('width', 800)
    .attr('height', 480)
    .style('display', 'block')
    .style('margin', '6px auto')

  let line = d3.svg.line()
    .x((d) => { return d.x; })
    .y((d) => { return d.y; });

  let width = parseInt(chart.style('width'));
  let height = parseInt(chart.style('height'));

  let xScale = d3.scale.linear()
    .domain([0, _.max(frames.map((f) => { return f.x + f.width }))])
    .range([0, width]);
  let yScale = d3.scale.linear()
    .domain([0, _.max(frames.map((f) => { return f.y + f.height }))])
    .range([0, height]);

  // Create binding
  let frameGroup = chart.selectAll('g')
    .data(frames).enter()
    .append('g')
    .on('mouseover', updatePath)

  // Create the rectangles
  let frameRectGroup = frameGroup.append('rect')
    .attr('x', (d) => { return xScale(d.x) + d.pathDepth + options.framePadding })
    .attr('y', (d) => { return yScale(d.y) + d.pathDepth + options.framePadding })
    .attr('id', (d) => { return `${svgContainerId}FrameRect-${d.index}` })
    .style('fill', (d) => { return options.colorScale(d.label) })
    .style('stroke', 'none')
    .style('stroke-width', '3px')
    .style('opacity', '.9')
    .attr('width',  (d) => { return xScale(d.width) - 2 * d.pathDepth - options.framePadding })
    .attr('height', (d) => { return yScale(d.height) - 2 * d.pathDepth - options.framePadding })
    .on('mousemove', (d) => {
      frameGroup.selectAll(parentFrameSelector(d))
        .style('stroke', '#00ffff');
    })
    .on('mouseout',  (d) => {
      frameGroup.selectAll(parentFrameSelector(d))
        .style('stroke', 'none')
    })
    .append('svg:title')
      .text((d) => { return d.label })

  return chart;
};

renderGraph('d3-target', data);

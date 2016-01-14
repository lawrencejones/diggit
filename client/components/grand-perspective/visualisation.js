'use strict';

const _ = require('lodash');
const remote = require('remote');
const frame = remote.getGlobal('frame');
const d3 = require('d3');
const $ = require('jquery');

const defaultGraphOptions = () => {
  return {
    framePadding: 1,  // padding between frame rects
    textPadding: { top: 0, bottom: 0, left: 3, right: 3 },  // text label padding
    colorScale: d3.scale.category20b(),  // color scale for chart colors
  };
};

const processFrames = (frames) => {
  let maxWidth = _.max(frames.map((f) => { return f.x + f.w }));
  let maxHeight = _.max(frames.map((f) => { return f.y + f.h }));
  let totalVolume = maxWidth * maxHeight;

  return {
    maxWidth, maxHeight, totalVolume,
    frames: _.each(frames, (f, i) => {
      _.extend(f, {
        index: i,
        score: f.score || Math.round(100 * (f.w * f.h) / totalVolume),
        parent: _.find(frames, (_f) => {
          return f !== _f && f.label.lastIndexOf(_f.label) === 0
        }),
      });
    }),
  };
}

const renderGrandPerspective = (svgContainerId, unprocessedFrames, userOptions) => {
  let options = _.transform(defaultGraphOptions(), (options, value, key) => {
    options[key] = userOptions[key] || value;
  });

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
  })($('<ol class="breadcrumb"><li>&nbsp;</li></ol>').appendTo(`#${svgContainerId}`))

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
    .domain([0, _.max(frames.map((f) => { return f.x + f.w }))])
    .range([0, width]);
  let yScale = d3.scale.linear()
    .domain([0, _.max(frames.map((f) => { return f.y + f.h }))])
    .range([0, height]);

  // Create binding
  let frameGroup = chart.selectAll('g')
    .data(frames).enter()
    .append('g')
    .on('mouseover', updatePath)

  // Create the rectangles
  let frameRectGroup = frameGroup.append('rect')
    .attr('x', (d) => { return xScale(d.x) + options.framePadding })
    .attr('y', (d) => { return yScale(d.y) + options.framePadding })
    .attr('id', (d) => { return `${svgContainerId}FrameRect-${d.index}` })
    .style('fill', (d) => { return options.colorScale(d.label) })
    .style('stroke', 'none')
    .style('stroke-width', '3px')
    .style('opacity', '.9')
    .attr('width',  (d) => { return Math.max(1, xScale(d.w) - options.framePadding) })
    .attr('height', (d) => { return Math.max(1, yScale(d.h) - options.framePadding) })
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

module.exports = { defaultGraphOptions, processFrames, renderGrandPerspective };
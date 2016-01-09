'use strict';

const remote = require('remote');
const frame = remote.getGlobal('frame');

function rectangularAreaChartDefaultSettings(){
  return {
    expandFromLeft: true, // Areas expand from left to right.
      expandFromTop: false, // Areas expand from top to bottom.
      animate: true, // Controls animation when chart loads.
      animateDuration: 2000, // The duration of the animation when the chart loads.
      animateDelay: 0, // The delay between the chart loading and the actual load animation starting.
      animateDelayBetweenBoxes: 200, // Adds a delay between box expansions during the load animation.
      colorsScale: d3.scale.category20b(), // The color scale to use for the chart areas.
      textColorScale: d3.scale.ordinal().range(["#fff"]), // The color scale to use for the chart text.
      textPadding: {top: 0, bottom: 0, left: 3, right: 3}, // Category text padding.
      maxValue: -1, // The charts maximum value. If this value is greater than the largest value displayed on the chart, this will cause the largest chart value to take up less area than the maximum height and width of the chart.
      labelAlignDiagonal: false, // Aligns the category label text to the charts diagonal.
      valueTextAlignDiagonal: false, // Aligns the value text to the charts diagonal.
      displayValueText: true, // Display the value text.
      valueTextPadding: {top: 0, bottom: 0, left: 3, right: 3}, // Value text padding.
      valueTextCountUp: true // Causes the value text to count up from 0 during the chart load animation.
  };
}

/*
 * Data must be a an array of json objects formatted:
 * [{value: 123, label: "Category 1", valuePrefix: "Some Prefix ", valueSuffix: " things"}, {value: 23, label: "Category 2", valuePrefix: "Some Prefix ", valueSuffix: " things"}]
 * value and label are required.
 * valuePrefix and valueSuffix are optional.
 */
function loadRectangularAreaChart(elementId, data, settings){
  var dataSorter = function(a, b) {
    return a.value - b.value;
  };

  var valueFormatter = function(d, overrideValue){
    var valueText = d.valuePrefix? d.valuePrefix : "";
    valueText += overrideValue != null? overrideValue : d.value;
    valueText += d.valueSuffix? d.valueSuffix : "";
    return valueText;
  };

  if(settings == null) settings = rectangularAreaChartDefaultSettings();

  var svg = d3.select("#" + elementId);

  // Some dummy text is needed so that we can get the text height before attaching text to any paths.
  var dummyText = svg.append("text")
    .attr("class", "rectangularAreaChartText")
    .text("N");
  var textHeight = dummyText.node().getBBox().height;

  // Sort the data so that boxes are drawn in the right order.
  data.sort(dataSorter);
  data.reverse();
  var dataMax = Math.max(data[0].value, settings.maxValue);

  var width = parseInt(svg.style("width"));
  var height = parseInt(svg.style("height"));

  // Scales for the height and width of the boxes.
  var sizeScaleWidth = d3.scale.sqrt().range([0, width]).domain([0, dataMax]);
  var sizeScaleHeight = d3.scale.sqrt().range([0, height]).domain([0, dataMax]);

  var line = d3.svg.line()
    .x(function(d){return d.x;})
    .y(function(d){return d.y;});

  // Each box is in it's own group and the animation is done by moving the group.
  var boxGroup = svg.selectAll("g")
    .data(data).enter()
    .append("g")
    .attr("transform", function(d){
      if(settings.animate) {
        var x = settings.expandFromLeft ? sizeScaleWidth(d.value) * -1 : width;
        var y = settings.expandFromTop ? sizeScaleHeight(d.value) * -1 : height;
        return "translate(" + x + "," + y + ")";
      } else {
        var x = settings.expandFromLeft? 0 : width - sizeScaleWidth(d.value);
        var y = settings.expandFromTop? 0 : height - sizeScaleHeight(d.value);
        return "translate(" + x + "," + y + ")";
      }
    })
  // A clip path is necessary to cut off text so that it doesn't get drawn outside the box during the loading animation.
  .attr("clip-path", function(d,i) { return "url(#" + elementId + "ClipPath" + i + ")"; });

  // The box clip area.
  boxGroup.append("defs")
    .append("clipPath")
    .attr("id", function(d,i) { return elementId + "ClipPath" + i; })
    .append("rect")
    .attr("width", function(d) { return sizeScaleWidth(d.value); })
    .attr("height", function(d) { return sizeScaleHeight(d.value); });

  // The box.
  boxGroup.append("rect")
    .attr("width", function(d) { return sizeScaleWidth(d.value); })
    .attr("height", function(d) { return sizeScaleHeight(d.value); })
    .style("fill", function(d) { return settings.colorsScale(d.label); })
    .append("title")
    .text(function(d) { return d.label + " (" + valueFormatter(d) + ")"; });

  // Animate the box.
  if(settings.animate){
    boxGroup.transition()
      .delay(function (d, i) { return settings.animateDelay + (settings.animateDelayBetweenBoxes * i); })
      .duration(settings.animateDuration)
      .attr("transform", function(d){
        var x = settings.expandFromLeft? 0 : width - sizeScaleWidth(d.value);
        var y = settings.expandFromTop? 0 : height - sizeScaleHeight(d.value);
        return "translate(" + x + "," + y + ")"
      });
  }

  // Add a path to attach the category label text to.
  boxGroup.append("path")
    .attr("id", function(d,i) { return elementId + "HozPath" + i; })
    .attr("d", function(d,i) {
      var textX1, textX2, textY;
      if(settings.labelAlignDiagonal){
        textX1 = settings.textPadding.left;
        textX2 = sizeScaleWidth(d.value) - settings.textPadding.right;
      } else {
        if(settings.expandFromLeft){
          textX1 = settings.textPadding.left;
          textX2 = sizeScaleWidth(d.value) * 2 + settings.textPadding.left;
        } else {
          textX1 = sizeScaleWidth(d.value) * -1 - settings.textPadding.right;
          textX2 = sizeScaleWidth(d.value) - settings.textPadding.right;
        }
      }
      textY = settings.expandFromTop? sizeScaleHeight(d.value) - settings.textPadding.bottom - textHeight/4 : textHeight + settings.textPadding.top;
      return line([{x: textX1, y: textY}, {x: textX2, y: textY}]);
    });

  // Set up the label text location.
  var labelStartOffset, labelEndOffset, labelTextAnchor;
  if(settings.labelAlignDiagonal){
    if(settings.expandFromLeft){
      labelStartOffset = "100%";
      labelTextAnchor = "end";
    } else {
      labelStartOffset = "0%";
      labelTextAnchor = "start";
    }
  } else {
    if(settings.expandFromLeft){
      labelStartOffset = "50%";
      labelEndOffset = "0%";
      labelTextAnchor = "start";
    } else {
      labelStartOffset = "50%";
      labelEndOffset = "100%";
      labelTextAnchor = "end";
    }
  }
  if(settings.animate == false && settings.labelAlignDiagonal == false){
    labelStartOffset = labelEndOffset;
  }

  // Add the category label text.
  var labelPath = boxGroup.append("text")
    .attr("class", "rectangularAreaChartText")
    .style("fill", function(d) { return settings.textColorScale(d.label); })
    .attr("id", function(d,i) { return elementId + "LabelText" + i; })
    .append("textPath")
    .attr("startOffset", labelStartOffset)
    .style("text-anchor", labelTextAnchor)
    .attr("xlink:href", function(d,i) { return "#" + elementId + "HozPath" + i; })
    .text(function(d) { return d.label; });
  if(settings.animate && settings.labelAlignDiagonal == false){
    labelPath.transition()
      .delay(function (d, i) { return settings.animateDelay + (settings.animateDelayBetweenBoxes * i); })
      .duration(settings.animateDuration)
      .attr("startOffset", labelEndOffset);
  }

  if(settings.displayValueText){
    // Add a path to attach the value text to.
    boxGroup.append("path")
      .attr("d", function(d) {
        var textX, textY1, textY2;
        if(settings.valueTextAlignDiagonal){
          textY1 = settings.expandFromLeft? sizeScaleHeight(d.value) - settings.valueTextPadding.left : settings.valueTextPadding.left;
          textY2 = settings.expandFromLeft? settings.valueTextPadding.right : sizeScaleHeight(d.value) - settings.valueTextPadding.right;
        } else {
          if(settings.expandFromLeft) {
            if(settings.expandFromTop){
              textY1 = sizeScaleHeight(d.value) * 2 + settings.valueTextPadding.right;
              textY2 = settings.valueTextPadding.right;
            } else {
              textY1 = sizeScaleHeight(d.value) - settings.valueTextPadding.left;
              textY2 = sizeScaleHeight(d.value) * -1 - settings.valueTextPadding.left;
            }
          } else {
            if(settings.expandFromTop){
              textY1 = settings.valueTextPadding.left;
              textY2 = sizeScaleHeight(d.value) * 2 + settings.valueTextPadding.left;
            } else {
              textY1 = sizeScaleHeight(d.value) * -1 - settings.valueTextPadding.right;
              textY2 = sizeScaleHeight(d.value) - settings.valueTextPadding.right;
            }
          }
        }
        textX = settings.expandFromLeft? sizeScaleWidth(d.value) - settings.valueTextPadding.bottom - textHeight/4 : textHeight/4 + settings.valueTextPadding.bottom;
        return line([{x: textX, y: textY1}, {x: textX, y: textY2}]);
      })
    .attr("id", function(d,i) { return elementId + "VertPath" + i; });

    // Set up the value text location.
    var valueTextStartOffset, valueTextEndOffset, valueTextTextAnchor;
    if(settings.valueTextAlignDiagonal) {
      if((settings.expandFromLeft && settings.expandFromTop) ||
          (settings.expandFromLeft == false && settings.expandFromTop == false)) {
            valueTextStartOffset = "0%";
            valueTextTextAnchor = "start";
          } else {
            valueTextStartOffset = "100%";
            valueTextTextAnchor = "end";
          }
    } else {
      if((settings.expandFromLeft && settings.expandFromTop) ||
          (settings.expandFromLeft == false && settings.expandFromTop == false)){
            valueTextStartOffset = "50%";
            valueTextEndOffset = "100%";
            valueTextTextAnchor = "end";
          } else {
            valueTextStartOffset = "50%";
            valueTextEndOffset = "0%";
            valueTextTextAnchor = "start";
          }
    }
    if(settings.animate == false && settings.valueTextAlignDiagonal == false){
      valueTextStartOffset = valueTextEndOffset;
    }

    // Add the value text.
    var valuePath = boxGroup.append("text")
      .attr("class", "rectangularAreaChartText")
      .style("fill", function(d) { return settings.textColorScale(d.label); })
      .append("textPath")
      .attr("startOffset", valueTextStartOffset)
      .style("text-anchor", valueTextTextAnchor)
      .attr("xlink:href", function(d,i) { return "#" + elementId + "VertPath" + i; });
    var valueText = valuePath.append("tspan") // A tspan is necessary so that we can animate both the movement of the text and it's counting up from 0.
      .text(function(d) { return settings.animate&&settings.valueTextCountUp? valueFormatter(d, 0) : valueFormatter(d); });

    // Animate the text movement.
    if(settings.animate && settings.valueTextAlignDiagonal == false) {
      valuePath.transition()
        .delay(function (d, i) { return settings.animateDelay + (settings.animateDelayBetweenBoxes * i); })
        .duration(settings.animateDuration)
        .attr("startOffset", valueTextEndOffset);
    }

    // Animate the value counting up from 0.
    if(settings.animate && settings.valueTextCountUp){
      valueText.transition()
        .delay(function (d, i) { return settings.animateDelay + (settings.animateDelayBetweenBoxes * i); })
        .duration(settings.animateDuration * 1.25)
        .tween("text", function(d){
          var i = d3.interpolate(this.textContent, d.value);
          return function(t) { this.textContent = valueFormatter(d, Math.round(i(t))); }
        });
    }
  }
}

// THIS IS START OF DATA CODE //////////////////////////////////////////////////

var data1 = [
  { value: "42", label: "parturient montes", valueSuffix: " things" },
  { value: "69", label: "id, mollis nec", valueSuffix: " things" },
  { value: "29", label: "lacus.Ut", valueSuffix: " things" },
  { value: "52", label: "a ultricies adipiscing", valueSuffix: " things" },
];


var config1 = rectangularAreaChartDefaultSettings();
config1.expandFromLeft = false;
config1.colorsScale = d3.scale.category20b();
config1.maxValue = 100;
loadRectangularAreaChart("rectangularareachart1", data1, config1);

var data2 = [
  { value: "78", label: "Duis", valuePrefix: "Area of " },
  { value: "37", label: "Cras", valuePrefix: "Area of " },
  { value: "55", label: "elit sed consequat", valuePrefix: "Area of " },
];

var config2 = rectangularAreaChartDefaultSettings();
config2.colorsScale = d3.scale.ordinal().range(["#fc8d59","#ffffbf","#91bfdb"]); //palette from colorbrewer https://github.com/mbostock/d3/tree/master/lib/colorbrewer
config2.textColorScale = d3.scale.ordinal().range(["#444","#333","#222"]);
config2.labelAlignDiagonal = true;
config2.valueTextAlignDiagonal = true;
config2.valueTextPadding.right = 18;
config2.animateDelay = 1000;
config2.animateDelayBetweenBoxes = 0;
config2.valueTextCountUp = false;
loadRectangularAreaChart("rectangularareachart2", data2, config2);

var data3 = [
  { value: "40", label: "massa. Quisque" },
  { value: "34", label: "rhoncus. Proin nisl" },
  { value: "45", label: "ipsum nunc" },
  { value: "64", label: "pharetra" },
  { value: "95", label: "parturient montes" },
  { value: "87", label: "pede, ultrices" },
  { value: "80", label: "nascetur" }
];

var config3 = rectangularAreaChartDefaultSettings();
config3.expandFromLeft = false;
config3.expandFromTop = true;
config3.maxValue = 100;
config3.colorsScale = d3.scale.ordinal().range(["#fff7fb","#ece2f0","#d0d1e6","#a6bddb","#67a9cf","#3690c0","#02818a","#016c59","#014636"]);  //palette from colorbrewer https://github.com/mbostock/d3/tree/master/lib/colorbrewer
config3.textColorScale = d3.scale.ordinal().range(["#555","#777","#999","#aaa","#ddd","#fff","#fff"]);
config3.animateDelay = 2000;
loadRectangularAreaChart("rectangularareachart3", data3, config3);

var data4 = [
  { value: "32", label: "consectetuer adipiscing" },
  { value: "62", label: "ipsum" }
];

var config4 = rectangularAreaChartDefaultSettings();
config4.expandFromLeft = true;
config4.expandFromTop = true;
config4.maxValue = 100;
config4.labelAlignDiagonal = true;
config4.animateDelay = 3500;
config4.displayValueText = false;
config4.animateDelayBetweenBoxes = 0;
config4.colorsScale = d3.scale.ordinal().range(["#7570b3","#e7298a","#66a61e"]);  //palette from colorbrewer https://github.com/mbostock/d3/tree/master/lib/colorbrewer
config4.textColorScale = d3.scale.ordinal().range(["#e7298a","#7570b3","#66a61e"]);
loadRectangularAreaChart("rectangularareachart4", data4, config4);

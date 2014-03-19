$(document).ready(function() {

  $('.share_badge').on('click', function () {
    var badge_id = this.getAttribute('data-badge-id'),
        earned_id = this.getAttribute('data-earned-badge-id')
    $.ajax({
      url: '/badges/' + badge_id + '/earned_badges/' + earned_id + '/toggle_shared',
      method: 'post',
      data: {
        earned_badge_id: earned_id
      },
      success: function (data) {
        if (data.shared) {
          $('#shared_' + badge_id).text("Stop Sharing")
        } else {
          $('#shared_' + badge_id).text("Share")
        }
        $('#shared_' + badge_id).toggleClass('success warning')
        $('#shared_' + badge_id).toggleClass('add_badge remove_badge')
      }
    })
  })

    function createOptions () {
    return {
    chart: {
      type: 'bar',
      backgroundColor:null,
    },
    title: {
      style: {
        color: "#FFFFFF"
      }
    },
    colors: [
     '#1A1EB2',
     '#303285',
     '#6dd8f0',
     '#080B74',
     '#00BD39',
     '#238D43',
     '#007B25',
     '#37DE6A',
     '#64DE89',
     '#FFCC00',
     '#BFBD30',
     '#A6A400',
     '#FFFD40',
     '#FFFD73'
  ],

    credits: {
      enabled: false
    },
    xAxis: {
      title: {
        text: ' '
      },
      labels: {
        style: {
          color: "#222"
        }
      }
    },
    yAxis: {
      min: 0,
      title: {
        text: 'Available Points'
      }
    },
    labels: {
      plotLines: [{
        color: '#808080'
      }]
    },
    tooltip: {
      formatter: function() {
        return '<b>'+ this.series.name +'</b><br/>'+
        this.y + ' points';
      }
    },
    plotOptions: {
      series: {
        stacking: 'normal'
      }
    },
    legend: {
      backgroundColor: null,
      borderColor:null,
      reversed: true,
      itemStyle: {
        color: '#CCCCCC'
      }
    },
  };
  }

    var chart, categories, assignment_type_name, scores;
    if ($('#userBarInProgress').length) {
      var data = JSON.parse($('#data-predictor').attr('data-predictor'));

      // Get Assignment Type Info
      var options = createOptions()
      options.chart.renderTo = 'userBarInProgress';
      options.title = { text: 'My Points' };
      options.xAxis.categories = { text: ' ' };
      options.yAxis.max = data.in_progress;
      options.series = data.scores;
      chart = new Highcharts.Chart(options);

      var options = createOptions()
      options.chart.renderTo = 'userBarTotal';
      options.title = { text: 'Total Possible Points' };
      options.xAxis.categories = { text: ' ' };
      options.yAxis.max = data.course_total;
      options.series = data.scores;
      chart = new Highcharts.Chart(options);
    };
});

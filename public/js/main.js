
var func1 = function(){
  (function ($, baseUrl, searchParams){
    'use strict';
    
    //select input 'q' by default
    var $q = $('input[name=q]');
    $q.focus();
    $q.select();

    //
    // Languages
    //

    $('.language-links a').click(function(evt) {
      var select = $(this),
          l = select.data('lang');

      if (l) {
        $.get(baseUrl + '/lang/set/' + l, function(data) {
          window.location.reload(true);
        });
      }
    });

    //
    // Facet Searches
    //

    $('.select').select2();

    $('select.search-facet').change(function(evt) {
      var select = $(this),
          index = select.data('index'),
          term = select.val();

      delete searchParams.start;

      searchParams.fq = searchParams.fq || [];

      if (!(searchParams.fq instanceof Array)) {
        searchParams.fq = [searchParams.fq];
      }

      searchParams.fq.push(index + ':' + term);
      var url = baseUrl + '/records' + '?' + $.param($.extend({}, searchParams), true);
      window.location.replace(url);
    });

    $('.remove-filter').click(function(evt) {

      var el = $(this),
          filter = el.data('delete-filter');

      delete searchParams.fq.start;

      if (searchParams.fq) {

        if (searchParams.fq instanceof Array) {
          var found = $.inArray(filter, searchParams.fq);
          if (found > -1) {
            searchParams.fq.splice(found, 1);
          }
        } else if (typeof searchParams.fq === 'string') {
          delete searchParams.fq;
        }
      }

      var url = baseUrl + '/records' + '?' + $.param($.extend({}, searchParams), true);
      window.location.replace(url);
    });

    //
    // Mark Results
    //
    // note:
    //   use event delegation for efficiency.
    //   http://jsperf.com/jquery-event-delegation/51
    //

    $('.results').on('click', 'button.mark', markFn);
    $('button#mark').on('click', markFn);

    function markFn (evt){
      evt.preventDefault();
      var $el = $(this);
      var marked = $el.data('marked');
      var url = baseUrl + '/marked/' + $el.data('id');
      var req;

      if (!marked){

        req = $.ajax({
          type: 'POST',
          url: url,
          dataType: 'json'
        }).done(function(data){
          $('.total-marked').text(data.total);
          $el.data('marked', 1).text('Unmark');
        });

      } else {

        req = $.ajax({
          type: 'DELETE',
          url: url,
          dataType: 'json'
        }).done(function(data){
          $('.total-marked').text(data.total);
          $el.data('marked', 0).text('Mark');
        });

      }

      req.fail(function(jqXHR, textStatus){
        //console.log(textStatus);
      });

    }

    $('button.unmark-all').on('click', function(evt){
      evt.preventDefault();

      var req = $.ajax({
        type: 'DELETE',
        url: baseUrl + '/marked',
        dataType: 'json'
      });
      req.done(function(data){
        window.location.replace(baseUrl + "/marked");
      });
      req.fail(function(jqXHR, textStatus){
        //console.log(textStatus);
      });
    });

    //
    // Save Searches
    //

    $('.save-search').click(function(evt){
      evt.preventDefault();


      var params = $.extend({}, searchParams);
      delete params.start;

      var req = $.ajax({
        type: 'POST',
        url: baseUrl + '/saved-searches',
        data: params,
        dataType: 'json'
      });
      req.done(function(data){
        $('.total-saved-searches').text(data.total);
      });
      req.fail(function(jqXHR, textStatus){
        //console.log(textStatus);
      });
    });

    $('.unsave').click(function(evt){
      evt.preventDefault();

      var $a = $(this);
      var i = $a.data('id');
      var url = baseUrl + '/saved-searches/' + i;

      var req = $.ajax({
        type: 'DELETE',
        url: url,
        dataType: 'json'
      });
      req.done(function(data){
        window.location.replace(baseUrl + "/saved-searches");
      });
      req.fail(function(jqXHR, textStatus){
        //console.log(textStatus);
      });
    });

    $('.unsave-all').click(function(evt){
      evt.preventDefault();

      var req = $.ajax({
        type: 'DELETE',
        url: baseUrl + '/saved-searches',
        dataType: 'json'
      });
      req.done(function(data){
        window.location.replace(baseUrl + "/saved-searches");
      });
      req.fail(function(jqXHR, textStatus){
        //console.log(textStatus);
      });

    });

  })(window.jQuery,window.baseUrl,window.searchParams);

};
/*
  auto detect Right to Left oriëntation of text
*/
var func2 = function(){
  (function($){
    $(document).ready(function(){
      $("#q").keyup(function(){
        checkDirection(this);
      });
    });
  })(window.jQuery) 
};
jQuery(document).ready(function(){
  func1();
  func2();
});



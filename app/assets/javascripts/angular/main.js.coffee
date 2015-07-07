@gradecraft = angular.module('gradecraft', ['restangular', 'ui.sortable', 'ng-rails-csrf', 'ngResource', 'ngAnimate', 'templates'])

INTEGER_REGEXP = /^\-?\d+$/
@gradecraft.directive "integer", ->
  require: "ngModel"
  link: (scope, elm, attrs, ctrl) ->
    ctrl.$parsers.unshift (viewValue) ->
      if INTEGER_REGEXP.test(viewValue)
        # it is valid
        ctrl.$setValidity "integer", true
        viewValue
      else
        # it is invalid, return undefined (no model update)
        ctrl.$setValidity "integer", false
        'undefined'

    return

@gradecraft.directive "collapseToggler", ->
  restrict : 'C',
  link: (scope, elm, attrs) ->
    elm.bind('click', ()->
      console.log("sam i am");
      elm.siblings().toggleClass('collapsed')
      #$(this).siblings('collapsable').toggleClass('collapsed')
    )
    return

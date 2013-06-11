/*jshint multistr: true */
var monodi = angular.module('monodi', []).
    filter('formatPath', function() {
        return function(input) {
            if (input) {
                var paths = input.split('/');
                paths.pop();
                return paths.join(' - ');
            }
        };
    }).filter('formatName', function() {
        return function(input) {
            if (input) return input.split('/').pop();
        };
    }).directive('match', function() {
        return {
            require: 'ngModel',
            restrict: 'A',
            link: function(scope, elem, attrs, ctrl) {
                ctrl.$parsers.unshift(function(viewValue) {
                    var test = scope;
                    attrs.match.split('.').forEach( function(part) {
                        test = test[part];
                    });

                    if (viewValue == test) {
                        ctrl.$setValidity('match', true);
                        return viewValue;
                    } else {
                        ctrl.$setValidity('match', false);
                        return undefined;
                    }
                });
            }
        };
    });
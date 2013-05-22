angular.module('monodi', []).
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
    });
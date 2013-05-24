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
    }).directive('filelistRepeat', function($parse) {
        return {
            link: function(scope, elem, attr) {
                var data = $parse(attr.filelistRepeat)(scope);
                var renderDocuments = function(data) {
                    angular.forEach(data, function(el) {
                        if (el.document_count > 0) {
                            var path = el.path;
                            angular.forEach(el.documents, function(el) {
                                elem.append('<tr>\
    <td><input type="checkbox" name="' + el.id +'" /></td>\
    <td>' + path + '</td>\
    <td>' + el.filename + '</td>\
    <td>\
        <div class="actions btn-group">\
            <button class="btn btn-danger"><i class="icon-trash icon-white"></i></button>\
            <button class="btn btn-inverse"><i class="icon-print icon-white"></i></button>\
            <button class="btn btn-info"><i class="icon-arrow-down icon-white"></i></button>\
            <button class="btn btn-primary" data-target="#fileInfos" data-toggle="modal"><i class="icon-info-sign icon-white"></i></button>\
        </div>\
    </td>\
</tr>');
                            });
                        }

                        if (el.children_count > 0) {
                            renderDocuments(el.folders);
                        }
                    });
                };

                if (data) {
                    renderDocuments(data);
                }
            }
        };
    }).directive('filetreeRepeat', function($parse) {
        return {
            link: function(scope, elem, attr) {
                var data = $parse(attr.filetreeRepeat)(scope);
                var tree = '';
                var renderDocuments = function(data) {
                    angular.forEach(data, function(el) {
                        tree += '<ul><li><button class="btn btn-link"><i class="icon-folder-close"></i> ' + el.title + '</button>';
                        if (el.document_count > 0) {
                            tree += '<ul>';
                            angular.forEach(el.documents, function(el) {
                                tree += '<li>\
    <input type="checkbox" /><button class="btn btn-link">' + el.filename + '</button>\
    <div class="actions btn-group">\
        <button class="btn btn-danger"><i class="icon-trash icon-white"></i></button>\
        <button class="btn btn-inverse"><i class="icon-print icon-white"></i></button>\
        <button class="btn btn-info"><i class="icon-arrow-down icon-white"></i></button>\
        <button class="btn btn-primary" data-target="#fileInfos" data-toggle="modal"><i class="icon-info-sign icon-white"></i></button>\
    </div>\
</li>';
                            });
                            tree += '</ul>';
                        }

                        if (el.children_count > 0) {
                            renderDocuments(el.folders);
                        }

                        tree += '</li></ul>';
                    });
                };

                if (data) {
                    renderDocuments(data);
                    elem.append(tree);
                }
            }
        };
    });
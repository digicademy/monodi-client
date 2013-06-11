function DocumentListCtrl($scope, $http) {
    $scope.toggle = function() {
        var $checkboxes = $('.fileList input[type="checkbox"]');
        if ($checkboxes.first().prop('checked') == true) {
            $checkboxes.prop('checked', true);
        } else {
            $checkboxes.prop('checked', false);
        }
    };

    $scope.openDocument = function(id) {
        $scope.setInfoDocument(id);
        $scope.$emit('openDocumentRequest', { id: id });
    };

    $scope.saveLocal = function(id) {
        $scope.getDocument(id, function() {
            localStorage['document' + id] = JSON.stringify(this);
            var documentList = localStorage['documentList'];
            if (documentList) {
                if (documentList.index(' ' + id + ',') < 0) {
                    localStorage['documentList'] += ' ' + id + ',';
                }
            } else {
                localStorage['documentList'] = ' ' + id + ',';
            }
            $scope.setLocal(id, true);
        });
    };

    $scope.removeLocal = function(id) {
        localStorage.removeItem('document' + id);
        var documentList = localStorage['documentList'];
        if (documentList) {
            localStorage['documentList'] = documentList.replace(' ' + id + ',', '');
        }
        $scope.setLocal(id, false);
    };

    $scope.documentinfo = function(id) {
        $scope.setInfoDocument(id);
        $scope.showDocumentInfo();
    };
}
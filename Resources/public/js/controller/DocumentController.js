function DocumentCtrl($scope, $http) {
	$scope.$on('openDocument', function() {
		monodi.document = new MonodiDocument({
			staticStyleElement	: document.getElementById("staticStyle"),
			dynamicStyleElement	: document.getElementById("dynamicStyle"),
			musicContainer		: document.getElementById("musicContainer"),
			xsltUrl				: "/bundles/digitalwertmonodiclient/js/monodi/mei2xhtml.xsl",
			meiString			: $scope.active.content
		});

		monodi.document.addCallback('deleteAnnotatedElement', function(data) {
			return confirm('Do you want to delete the ' + data.length + ' Annotations associated with this element?');
		});

		var typesrc = monodi.document.ANNOTATION_TYPES || {};
		types = '<p><select>';
		for (var type in typesrc) {
			types += '<option value="' + type + '">' + typesrc[type].label + '</option>';
		}
		$('#annotationModal').find('input').parent().before(types + '</select></p>');

		$scope.showView('main');
	});

	$scope.$on('saveDocument', function() {
		$scope.active.content = monodi.document.getSerializedDocument();
		/*$http.put(baseurl + 'api/v1/documents/' + $scope.active.id + '.json?access_token=' + $scope.access_token, angular.toJson($scope.active)).success(function (data) {
            //console.log(data);
        });*/

        localStorage['document' + $scope.active.id] = JSON.stringify($scope.active);
        var documentList = localStorage['documentList'];
        if (documentList) {
            if (documentList.indexOf(' ' + id + ',') < 0) {
                localStorage['documentList'] += ' ' + id + ',';
            }
        } else {
            localStorage['documentList'] = ' ' + id + ',';
        }
        $scope.setLocal($scope.active.id, true);

        $('#savedModal').modal('show');
	});
}
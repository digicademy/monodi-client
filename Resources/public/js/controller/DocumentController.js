function DocumentCtrl($scope, $http) {
	$scope.$on('openDocument', function() {
		monodi.document = new MonodiDocument({
			staticStyleElement	: document.getElementById("staticStyle"),
			dynamicStyleElement	: document.getElementById("dynamicStyle"),
			musicContainer		: document.getElementById("musicContainer"),
			xsltUrl				: "/bundles/digitalwertmonodiclient/js/monodi/mei2xhtml.xsl",
			meiUrl              : "/bundles/digitalwertmonodiclient/js/monodi/hodieCantandus.mei"//meiString			: $scope.active.content
		});

        $scope.showView('main');
    });

    monodi.document = new MonodiDocument({
		staticStyleElement	: document.getElementById("staticStyle"),
		dynamicStyleElement	: document.getElementById("dynamicStyle"),
		musicContainer		: document.getElementById("musicContainer"),
		xsltUrl				: "/bundles/digitalwertmonodiclient/js/monodi/mei2xhtml.xsl",
		meiUrl              : "/bundles/digitalwertmonodiclient/js/monodi/hodieCantandus.mei"//meiString			: $scope.active.content
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

    //save: monodi.document.getSerializedDocument()
}
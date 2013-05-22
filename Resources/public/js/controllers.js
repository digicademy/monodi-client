function DocumentListCtrl($scope) {
    $scope.documents = [
		{
			id: 1,
			filename: 'Band 1/Aachen/Aa13/Dokument 1',
			rev: '123hex',
			editor: 1,
			title: 'Dokument1',
			createdAt: '2013-03-08',
			editedAt: '2013-03-08',
			processNumber: '123a',
			editionNumber: 1
		}, {
			id: 2,
			filename: 'Band 1/Aachen/Aa13/Dokument 2',
			rev: '124hex',
			editor: 1,
			title: 'Dokument2',
			createdAt: '2013-03-08',
			editedAt: '2013-03-08',
			processNumber: '123b',
			editionNumber: 1
		}, {
			id: 3,
			filename: 'Editorenordner/Müller/Mein Ordner 1/Dokument3',
			rev: '125hex',
			editor: 2,
			title: 'Dokument3',
			createdAt: '2013-03-08',
			editedAt: '2013-03-08',
			processNumber: '123a',
			editionNumber: 2
		}
	];
}
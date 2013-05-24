function DocumentListCtrl($scope, $http) {
	/*$http.get(baseurl + 'api/v1/metadata.json?access_token=MGJlY2FlNThkNGRiYmE0NWQ3OTNlMzE2ZmIxMDI0NzUxNjQwMjU3OTM0NjU5ZmVhN2Q1M2JkMGIzYmJkMGJiYg').success(function (data) {
		$scope.documents = data;
	});*/

	$scope.documents = [
			{
                "children_count": 2,
                "document_count": 0,
                "id": 53,
                "title": "Title of Parent 1",
                "path": "title-of-parent-1",
                "root": 53,
                "folders": [
                {
                    "children_count": 0,
                    "document_count": 0,
                    "id": 54,
                    "title": "child 1 of Parent 1",
                    "path": "title-of-parent-1/child-1-of-parent-1",
                    "root": 53,
                    "folders": [],
                    "documents": []
                },
                {
                    "children_count": 1,
                    "document_count": 0,
                    "id": 55,
                    "title": "child 2 of Parent 1",
                    "path": "title-of-parent-1/child-2-of-parent-1",
                    "root": 53,
                    "folders": [
                    {
                        "children_count": 0,
                        "document_count": 1,
                        "id": 56,
                        "title": "child 1 of child 2 of Parent 1",
                        "path": "title-of-parent-1/child-2-of-parent-1/child-1-of-child-2-of-parent-1",
                        "root": 53,
                        "folders": [],
                        "documents": [
                        {
                            "id": 3,
                            "filename": "testdocument.mei.xml",
                            "rev": "00000000000",
                            "title": "Test Dokument 1"
                        }
                        ]
                    }
                    ],
                    "documents": []
                }
                ],
                "documents": []
            },
            {
                "children_count": 2,
                "document_count": 0,
                "id": 57,
                "title": "Band I",
                "path": "band-i",
                "root": 57,
                "folders": [
                {
                    "children_count": 3,
                    "document_count": 0,
                    "id": 58,
                    "title": "Aachen",
                    "path": "band-i/aachen",
                    "root": 57,
                    "folders": [
                    {
                        "children_count": 0,
                        "document_count": 0,
                        "id": 59,
                        "title": "Aa 13",
                        "path": "band-i/aachen/aa-13",
                        "root": 57,
                        "folders": [],
                        "documents": []
                    },
                    {
                        "children_count": 0,
                        "document_count": 0,
                        "id": 60,
                        "title": "Aa 16",
                        "path": "band-i/aachen/aa-16",
                        "root": 57,
                        "folders": [],
                        "documents": []
                    },
                    {
                        "children_count": 0,
                        "document_count": 0,
                        "id": 61,
                        "title": "B 25",
                        "path": "band-i/aachen/b-25",
                        "root": 57,
                        "folders": [],
                        "documents": []
                    }
                    ],
                    "documents": []
                },
                {
                    "children_count": 2,
                    "document_count": 0,
                    "id": 62,
                    "title": "Trier",
                    "path": "band-i/trier",
                    "root": 57,
                    "folders": [
                    {
                        "children_count": 0,
                        "document_count": 0,
                        "id": 63,
                        "title": "T 15",
                        "path": "band-i/trier/t-15",
                        "root": 57,
                        "folders": [],
                        "documents": []
                    },
                    {
                        "children_count": 0,
                        "document_count": 0,
                        "id": 64,
                        "title": "Ps 6",
                        "path": "band-i/trier/ps-6",
                        "root": 57,
                        "folders": [],
                        "documents": []
                    }
                    ],
                    "documents": []
                }
                ],
                "documents": []
            },
            {
                "children_count": 0,
                "document_count": 0,
                "id": 65,
                "title": "Band II",
                "path": "band-ii",
                "root": 65,
                "folders": [],
                "documents": []
            },
            {
                "children_count": 3,
                "document_count": 0,
                "id": 66,
                "title": "Editorenordner",
                "path": "editorenordner",
                "root": 66,
                "folders": [
                {
                    "children_count": 2,
                    "document_count": 0,
                    "id": 67,
                    "title": "Müller",
                    "path": "editorenordner/muller",
                    "root": 66,
                    "folders": [
                    {
                        "children_count": 0,
                        "document_count": 0,
                        "id": 68,
                        "title": "Mein Ordner 1",
                        "path": "editorenordner/muller/mein-ordner-1",
                        "root": 66,
                        "folders": [],
                        "documents": []
                    },
                    {
                        "children_count": 0,
                        "document_count": 0,
                        "id": 69,
                        "title": "Mein Ordner 2",
                        "path": "editorenordner/muller/mein-ordner-2",
                        "root": 66,
                        "folders": [],
                        "documents": []
                    }
                    ],
                    "documents": []
                },
                {
                    "children_count": 0,
                    "document_count": 0,
                    "id": 70,
                    "title": "Schulze",
                    "path": "editorenordner/schulze",
                    "root": 66,
                    "folders": [],
                    "documents": []
                },
                {
                    "children_count": 0,
                    "document_count": 0,
                    "id": 71,
                    "title": "Meier",
                    "path": "editorenordner/meier",
                    "root": 66,
                    "folders": [],
                    "documents": []
                }
                ],
                "documents": []
            }
        ];
}
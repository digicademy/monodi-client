function NavCtrl($scope, $http) {
	$scope.login = function(id) {
        $.ajax({
            url: baseurl + 'oauth/v2/auth?client_id=' + client_id + '&response_type=token&redirect_uri=' + client_uri
        }).done(function(data) {
            var form = data.match(/(<form(.|[\r\n])*\/form>)/)[0];
            if (form.length) {
                var $modal = $('#loginModal').empty();
                var $iframe = $('<iframe/>').appendTo($modal).contents().find('body').append(form).end().end().on('load', function() {
                    var hash = this.contentWindow.location.hash;
                    var start = hash.indexOf('access_token');
                    if (start > -1) {
                        hash.substr(start).split('&').forEach( function(val) {
                            val = val.split('=');
                            if (val[0] == 'access_token') { $scope.setAccessToken(val[1]); }
                            if (val[0] == 'refresh_token') { $scope.setRefreshToken(val[1]); }
                        });

                        $scope.$emit('reloadDocuments', {});
                        $modal.modal('hide');
                    }
                });
                $modal.modal('show');
            }
        });
        return false;
    };

    $scope.changePass = function(pass) {
        var request = '{"current_password":"' + pass.old + '","new":"' + pass.new +'"}';
        $http.put(baseurl + 'api/v1/profile/' + pass.name + '/password.json?access_token=' + $scope.access_token, request).success(function (data) {
            $('#changePassModal').find('.modal-body').find('.notice').remove().end().append('<p class="notice">Passwort wurde erfolgreich geändert</p>');
        }).error(function (data, status) {
            var error = '';
            switch (status) {
                case 404:
                    error = 'Der Nutzername konnte nicht gefunden werden.';
                break;
                case 403:
                    error = 'Sie sind nicht berechtigt das Passwort zu ändern. Bitte überprüfen Sie Ihren Loginstatus.';
                break;
                case 400:
                    error = 'Die Validierung Ihrer aktuellen Login-Daten ist fehlgeschlagen.';
                break;
                case 500:
                    error = 'Leider gab es einen Fehler auf dem Server. Bitte versuchen Sie es später erneut.';
            }
            $('#changePassModal').find('.modal-body').find('.notice').remove().end().append('<p class="notice">' + error + '</p>');
        });
    };

    $scope.forgot = function() {
        $(this).closest('.modal').modal('hide');
        $('#forgot').modal('show');

        return false;
    };
}
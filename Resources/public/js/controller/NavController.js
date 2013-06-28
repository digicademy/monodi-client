function NavCtrl($scope, $http) {
	$scope.login = function(id) {
        var url = baseurl + 'oauth/v2/auth?client_id=' + client_id + '&response_type=token&redirect_uri=' + client_uri,
            $modal = $('#loginModal').css({ width: 300, height: 260, marginLeft: -150 }).empty(),
            $iframe = $('<iframe />').attr('src', url).css({ width: 300, height: 260 });

        $iframe.off('load').on('load', function() {
            var hash = this.contentWindow.location.hash;
            var start = hash.indexOf('access_token');
            if (start > -1) {
                hash.substr(start).split('&').forEach( function(val) {
                    val = val.split('=');
                    if (val[0] == 'access_token') { $scope.setAccessToken(val[1]); }
                    if (val[0] == 'refresh_token') { $scope.setRefreshToken(val[1]); }
                });

                $scope.$emit('sync');
                $scope.$emit('reloadDocuments', {});
                $modal.modal('hide');

                $http.get(baseurl + 'api/v1/profile/?access_token=' + $scope.access_token).success(function (data) {
                    $scope.pass = data;
                });
            }
        });

        $iframe.appendTo($modal);
        $modal.modal('show');
        return false;
    };

    $scope.changePass = function(pass) {
        $http.put(baseurl + 'api/v1/profile/' + pass.slug + '/password.json?access_token=' + $scope.access_token, '{"current_password":"' + pass.old + '","new":"' + pass.new +'"}').success(function (data) {
            $('#changePassModal').find('.modal-body').find('.notice').remove().end().append('<p class="notice">Passwort wurde erfolgreich geändert</p>');
        }).error(function (data, status) {
            var error = '';
            switch (status) {
                case 404:
                    error = 'The username was not found.';
                break;
                case 403:
                    error = 'You are not authorized to change the password. Please check your login status.';
                break;
                case 400:
                    error = 'Your current login informations could not be verified.';
                break;
                case 500:
                    error = 'There was an error on the server. Please try again later.';
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
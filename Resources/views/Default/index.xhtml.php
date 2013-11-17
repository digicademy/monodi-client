<?php
/**
 * @see http://symfony.com/doc/current/cookbook/templating/PHP.html
 * @see http://symfony.com/doc/current/cookbook/assetic/asset_management.html
 * 
 * @var Symfony\Bundle\FrameworkBundle\Templating\PhpEngine $view  
 * $view['assets'] Symfony\Component\Templating\Helper\CoreAssetsHelper
 */
$bundleAssetPath = '/bundles/digitalwertmonodiclient/';
?>
<?php echo("<?xml version=\"1.0\" ?>\n"); ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" encoding="utf-8" manifest="/bundles/digitalwertmonodiclient/cache-manifest/cache.manifest">
    <head>
        <title>mono:di</title>
        
        <link rel="stylesheet" href="/bundles/digitalwertmonodiclient/css/main.css" />
        
        <script>
            baseurl = '<?php echo($baseUrl); ?>';
            client_id = '<?php echo($publicId); ?>';
            client_uri = location.href + 'authorized';
        </script>
        <script src="/bundles/digitalwertmonodiclient/js/monodi.js"></script>

        <style type="text/css" id="staticStyle"></style>
        <style type="text/css" id="dynamicStyle"></style>
    </head>
    <body ng-app="monodi" ng-controller="AppCtrl">
        <div class="views">
            <div class="main container" ng-controller="DocumentCtrl">
                <div id="musicContainer" ng-show="active"></div>
                <!-- saved -->
                <div id="savedModal" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="savedLabel" aria-hidden="true">
                    <div class="modal-header">
                        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                        <h3>Document saved</h3>
                    </div>
                    <div class="modal-body">
                        <p>The document you are editing has been saved.</p>
                    </div>
                    <div class="modal-footer">
                        <button class="btn" data-dismiss="modal" aria-hidden="true">Ok</button>
                    </div>
                </div>
            </div>

            <div class="files container" ng-controller="DocumentListCtrl">
                <div class="row-fluid">
                    <div class="fileviewToggle btn-group span4 offset8">
                        <button class="btn active"><i class="icon-align-left"></i> directory structure</button>
                        <button class="btn"><i class="icon-th-list"></i> document list</button>
                    </div>

                    <div class="batch btn-group span4">
                        <button class="btn dropdown-toggle btn-block" data-toggle="dropdown">Batch functions <span class="caret"></span></button>
                        <ul class="dropdown-menu">
                            <li><button class="btn btn-link" ng-click="printBatch()">print</button></li>
                            <li><button class="btn btn-link" ng-click="removeDocumentBatch()">delete</button></li>
                            <li><button class="btn btn-link" ng-click="saveLocalBatch()">save locally</button></li>
                            <li><button class="btn btn-link" ng-click="removeLocalBatch()">delete locally</button></li>
                        </ul>
                    </div>

                    <div class="fileviews">
                        <div class="fileStructure clearfix">
                            <div class="fileproperties form-horizontal">
                                <div class="control-group">
                                    <label for="fileName" class="control-label">file name</label>
                                    <div class="controls">
                                        <input type="text" id="fileName" ng-model="active.title"  />.mei
                                    </div>
                                </div>
                            </div>
                            <ul>
                                <li ng-repeat="el in documents" ng-include="'/bundles/digitalwertmonodiclient/js/templates/tree.html'"></li>
                            </ul>
                        </div>

                        <div class="fileList clearfix">
                            <table class="table table-bordered table-striped">
                                <thead>
                                    <tr>
                                        <th class="span1"><input type="checkbox" ng-click="toggle()" /></th>
                                        <th class="span6">Path</th>
                                        <th class="span4">Name</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody class="table-hover">
                                    <tr ng-repeat="el in files">
                                        <td><input type="checkbox" name="{{el.id}}" id="list-document-{{el.id}}" /></td>
                                        <td>{{el.path}}</td>
                                        <td><button class="btn btn-link" ng-click="openDocument(el.id)">{{el.filename}}</button></td>
                                        <td>
                                            <div class="actions btn-group">
                                                <button class="btn btn-danger" ng-click="removeDocument(el.id)"><i class="icon-trash icon-white"></i></button>
                                                <button class="btn btn-inverse" ng-click="print(el.id)"><i class="icon-print icon-white"></i></button>
                                                <button class="btn btn-info" ng-click="saveDocumentLocal(el.id)" ng-hide="el.local"><i class="icon-arrow-down icon-white"></i></button>
                                                <button class="btn btn-warning" ng-click="removeDocumentLocal(el.id)" ng-show="el.local"><i class="icon-ban-circle icon-white"></i></button>
                                                <button class="btn btn-primary" ng-click="documentinfo(el.id)" data-toggle="modal"><i class="icon-info-sign icon-white"></i></button>
                                            </div>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                <!-- createFolder -->
                <div id="createFolderModal" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="directoryLabel" aria-hidden="true">
                    <div class="modal-header">
                        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                        <h3>New directory name</h3>
                    </div>
                    <form name="createFolderForm" ng-submit="createFolder(foldername)">
                        <div class="modal-body">
                            <p>
                                <input type="text" name="foldername" ng-model="foldername" placeholder="Foldername" required="required" />
                                <span class="error" ng-show="createFolder.foldername.$error.required">!</span>
                            </p>
                        </div>
                        <div class="modal-footer">
                            <button class="btn btn-primary" type="submit">create folder</button>
                            <button class="btn btn-warning" data-dismiss="modal" style="float:left">cancel</button>
                        </div>
                    </form>
                </div>
            </div>

            <!-- Provisional inlines styles: Here is a problem: Firefox needs "bottom: 0", 
                 Chrome "bottom: -100px" or less (like -160) and overflow:hidden on <body> -->
            <div class="help container" style="position: absolute; width: 100%; top: 43px; bottom: 0; display: block;overflow:hidden">
                <iframe src="/bundles/digitalwertmonodiclient/help/help.xhtml"
                    style="position: absolute; top:45px; height:100%;width:100%;transform:translate(-2px,-47px);-webkit-transform:translate(-2px,-47px)"></iframe>
            </div>
        </div>

        <!-- fileinfos -->
        <div id="fileInfosModal" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="FileInfosLabel" aria-hidden="true">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
            <h3 id="myModalLabel">Document Properties</h3>
          </div>
          <div class="modal-body">
            <table class="table table-bordered table-striped">
                <tbody class="table-hover">
                    <tr>
                        <th class="span2">Name</th>
                        <td>{{info.title}}</td>
                    </tr>
                    <tr>
                        <th class="span2">Filename</th>
                        <td>{{info.filename}}</td>
                    </tr>
                    <tr>
                        <th class="span2">Path</th>
                        <td>{{info.path}}</td>
                    </tr>
                    <tr>
                        <th class="span2">Revision</th>
                        <td>{{info.rev}}</td>
                    </tr>
                    <tr>
                        <th class="span2">Locally available</th>
                        <td>{{info.local}}</td>
                    </tr>
                </tbody>
            </table>
          </div>
        </div>

        <nav ng-controller="NavCtrl">
            <div class="navbar navbar-inverse navbar-fixed-top">
                <div class="navbar-inner">
                    <div class="container">
                        <button type="button" class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
                            <span class="icon-bar"></span>
                            <span class="icon-bar"></span>
                            <span class="icon-bar"></span>
                        </button>
                        <div class="brand">mono:di</div>
                        <div class="nav-collapse collapse">
                            <ul class="nav">
                                <li>
                                    <div class="btn-group">
                                        <button class="btn btn-link dropdown-toggle" data-toggle="dropdown" ng-click="showView('main')">Document <span class="caret"></span></button>
                                        <ul class="dropdown-menu">
                                            <li><button class="btn btn-link" ng-click="newDocumentDialog()">New</button></li>
                                            <li><button class="btn btn-link" ng-click="saveDocument()" ng-show="active">Save</button></li>
                                            <li><button class="btn btn-link" ng-click="saveNewDocument()" ng-show="active">Save as ...</button></li>
                                            <li><button class="btn btn-link" ng-click="printDocument()" ng-show="active">Print</button></li>
                                            <li><button class="btn btn-link" ng-click="showDocumentInfo()" ng-show="active">Properties</button></li>
                                            <li class="divider"></li>
                                            <li><button class="open btn btn-link" ng-click="showView('files')">Open</button></li>
                                        </ul>
                                    </div>
                                </li>
                                <li><button class="filecontrol btn btn-link" ng-click="showView('files')">Management</button></li>
                                <li class="right"><button class="help btn btn-link" ng-click="showView('help')">Help</button></li>
                                <li class="right">
                                    <button class="btn btn-link" data-target="#changePassModal" data-toggle="modal" ng-show="access_token">Profil</button>
                                    <button class="btn btn-link" ng-click="login()" ng-hide="access_token">Login</button>
                                </li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>

            <!-- login -->
            <div id="loginModal" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="LoginLabel" aria-hidden="true">
                <form action="login_check" method="post">
                    <div class="modal-header">
                        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                        <h3>Login</h3>
                    </div>
                    <div class="modal-body">
                        <p><input type="text" id="loginname" placeholder="Benutzername" /></p>
                        <p><input type="password" id="loginpass" placeholder="Passwort" /></p>
                    </div>
                    <div class="modal-footer">
                        <button class="btn forgot" data-dismiss="modal" aria-hidden="true">Forgot your password?</button>
                        <button type="submit" class="btn btn-primary">Login</button>
                    </div>
                </form>
            </div>

            <!-- forgot -->
            <div id="forgotModal" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="LoginLabel" aria-hidden="true">
                <div class="modal-header">
                    <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                    <h3>Forgot your password?</h3>
                </div>
                <div class="modal-body">
                    <p><input type="text" id="loginname" placeholder="Benutzername" /></p>
                </div>
                <div class="modal-footer">
                    <button class="btn btn-primary">request new password</button>
                </div>
            </div>

            <!-- change password -->
            <div id="changePassModal" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="ChangePasswordLabel" aria-hidden="true">
                <div class="modal-header">
                    <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                    <h3>change Password</h3>
                </div>
                <form name="changePassword" ng-submit="changePass(pass)">
                    <div class="modal-body">
                        <p>
                            <input type="text" name="username" ng-model="pass.username" placeholder="Username" disabled="disabled" />
                        </p>
                        <p>
                            <input type="password" name="old" ng-model="pass.old" placeholder="Current Password" required="required" />
                            <span class="error" ng-show="changePassword.old.$error.required">!</span>
                        </p>
                        <hr />
                        <p>
                            <input type="password" name="new" ng-model="pass.new" placeholder="Password" required="required" />
                            <span class="error" ng-show="changePassword.new.$error.required">!</span>
                        </p>
                        <p>
                            <input type="password" name="newR" ng-model="pass.newR" placeholder="Password" match="pass.new" required="required" />
                            <span class="error" ng-show="changePassword.newR.$error.required">!</span>
                            <div class="error" ng-show="changePassword.newR.$error.match">new passwords are not equal</div>
                        </p>
                    </div>
                    <div class="modal-footer">
                        <button class="btn btn-primary" type="submit">change password</button>
                    </div>
                </form>
            </div>
        </nav>

        <!-- annotation -->
        <div id="annotationModal" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="annotationLabel" aria-hidden="true">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                <h3>Comment</h3>
            </div>
            <form name="changeAnnotation" ng-submit="changeAnnotation()">
                <div class="modal-body">
                    <p>
                        <input type="text" placeholder="Label" />
                    </p>
                    <p>
                        <textarea placeholder="Text"></textarea>
                    </p>
                </div>
                <div class="modal-footer">
                    <button class="btn btn-primary" type="submit">save comment</button>
                    <button class="btn btn-warning" data-dismiss="modal" style="float:left">cancel</button>
                    <button class="btn btn-danger" data-dismiss="modal" style="float:left"><i class="icon-trash icon-white"></i></button>
                </div>
            </form>
        </div>

        <!-- new Modal Text -->
        <div id="newDocumentModal" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="newDocumentLabel" aria-hidden="true">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                <h3>Create new document </h3>
            </div>
            <form name="changeAnnotation" ng-submit="changeAnnotation()">
                <div class="modal-body">
                    <p>
                        <textarea id="newDocumentText" placeholder="Text"></textarea>
                    </p>
                </div>
                <div class="modal-footer">
                    <button class="btn btn-primary" data-dismiss="modal" type="submit" ng-click="newDocument(false)">create empty document</button>
                    <button class="btn btn-info" data-dismiss="modal" ng-click="newDocument(true)" style="float:left">create document from text</button>
                </div>
            </form>
        </div>

        <div id="printContainer">
            <button class="btn btn-inverse"><i class="icon-remove-circle icon-white"></i></button>
        </div>

        <div class="footer">
            <div class="container">
                <p>Concept, musical core and rendering: Thomas Weber for <a href="http://www.notengrafik.com/" target="_blank">notengrafik berlin</a><br />
                Server side development and user interface: <a href="http://www.digitalwert.de/" target="_blank">digitalwert&#174;</a>, Dresden</p>
            </div>
        </div>

        <script src="/bundles/digitalwertmonodiclient/js/monodi/MonodiDocument.js"></script>
        <script src="/bundles/digitalwertmonodiclient/js/main.js"></script>

        <!-- Google Analytics: change UA-XXXXX-X to be your site's ID.
        <script>
            var _gaq=[['_setAccount','UA-XXXXX-X'],['_trackPageview']];
            (function(d,t){var g=d.createElement(t),s=d.getElementsByTagName(t)[0];
            g.src=('https:'==location.protocol?'//ssl':'//www')+'.google-analytics.com/ga.js';
            s.parentNode.insertBefore(g,s)}(document,'script'));
        </script>-->
    </body>
</html>
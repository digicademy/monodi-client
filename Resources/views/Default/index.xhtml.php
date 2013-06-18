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
<html xmlns="http://www.w3.org/1999/xhtml" encoding="utf-8"><!--manifest="/bundles/digitalwertmonodiclient/cache-manifest/cache.manifest"-->
    <head>
        <title>mono:di</title>
        
        <link rel="stylesheet" href="/bundles/digitalwertmonodiclient/css/main.css" />
        
        <script> baseurl = 'http://notengrafik.dw-dev.de/'; </script>
        <script src="/bundles/digitalwertmonodiclient/js/vendor/modernizr.js"></script>
        <script src="/bundles/digitalwertmonodiclient/js/vendor/jquery.js"></script>
        <script src="/bundles/digitalwertmonodiclient/js/vendor/angular.js"></script>

        <script src="/bundles/digitalwertmonodiclient/js/controller/AppController.js"></script>
        <script src="/bundles/digitalwertmonodiclient/js/controller/NavController.js"></script>
        <script src="/bundles/digitalwertmonodiclient/js/controller/DocumentListController.js"></script>
        <script src="/bundles/digitalwertmonodiclient/js/controller/DocumentController.js"></script>
        <script src="/bundles/digitalwertmonodiclient/js/modules.js"></script>

        <style type="text/css" id="staticStyle"></style>
        <style type="text/css" id="dynamicStyle"></style>
    </head>
    <body ng-app="monodi" ng-controller="AppCtrl" data-appid="<?php echo($publicId); ?>">
        <div class="views">
            <div class="main container" ng-controller="DocumentCtrl">
                <div id="musicContainer"></div>
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
                            <li><button class="btn btn-link">print</button></li>
                            <li><button class="btn btn-link">delete</button></li>
                            <li><button class="btn btn-link">save locally</button></li>
                            <li><button class="btn btn-link">delete locally</button></li>
                        </ul>
                    </div>

                    <div class="fileviews">
                        <div class="fileStructure clearfix">
                            <ul>
                                <li ng-repeat="el in documents" ng-include="'/bundles/digitalwertmonodiclient/js/templates/tree.html'"></li>
                            </ul>
                        </div>

                        <div class="fileList clearfix">
                            <table class="table table-bordered table-striped span12">
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
                                                <button class="btn btn-danger"><i class="icon-trash icon-white" ng-show="online"></i></button>
                                                <button class="btn btn-inverse" ng-click="print(el.id)"><i class="icon-print icon-white"></i></button>
                                                <button class="btn btn-info" ng-click="saveLocal(el.id)" ng-hide="el.local" ng-show="online"><i class="icon-arrow-down icon-white"></i></button>
                                                <button class="btn btn-warning" ng-click="removeLocal(el.id)" ng-show="el.local"><i class="icon-ban-circle icon-white"></i></button>
                                                <button class="btn btn-primary" ng-click="documentinfo(el.id)" data-toggle="modal"><i class="icon-info-sign icon-white"></i></button>
                                            </div>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

            <div class="help container">
                <h2>Quare attende, quaeso.</h2>
                <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quid ergo attinet gloriose loqui, nisi constanter loquare? Duo Reges: constructio interrete. Facete M. Nosti, credo, illud: Nemo pius est, qui pietatem-; Nondum autem explanatum satis, erat, quid maxime natura vellet. Nescio quo modo praetervolavit oratio. Nam bonum ex quo appellatum sit, nescio, praepositum ex eo credo, quod praeponatur aliis. Hoc tu nunc in illo probas. </p>
                <p>Ut optime, secundum naturam affectum esse possit. Quamquam tu hanc copiosiorem etiam soles dicere. Intellegi quidem, ut propter aliam quampiam rem, verbi gratia propter voluptatem, nos amemus; Quod ea non occurrentia fingunt, vincunt Aristonem; Laboro autem non sine causa; An hoc usque quaque, aliter in vita? </p>
                <p>Poterat autem inpune; Ab hoc autem quaedam non melius quam veteres, quaedam omnino relicta. Ab his oratores, ab his imperatores ac rerum publicarum principes extiterunt. Ab his oratores, ab his imperatores ac rerum publicarum principes extiterunt. Nobis aliter videtur, recte secusne, postea; Sic exclusis sententiis reliquorum cum praeterea nulla esse possit, haec antiquorum valeat necesse est. Certe non potest. </p>
                <ul>
                    <li>Isto modo ne improbos quidem, si essent boni viri.</li>
                    <li>At, illa, ut vobis placet, partem quandam tuetur, reliquam deserit.</li>
                </ul>
                <p>Qui ita affectus, beatum esse numquam probabis; Vitae autem degendae ratio maxime quidem illis placuit quieta. Maximas vero virtutes iacere omnis necesse est voluptate dominante. Cupiditates non Epicuri divisione finiebat, sed sua satietate. Ego vero volo in virtute vim esse quam maximam; </p>
                <p>Hoc mihi cum tuo fratre convenit. Cur id non ita fit? Minime vero istorum quidem, inquit. Sed nonne merninisti licere mihi ista probare, quae sunt a te dicta? Potius inflammat, ut coercendi magis quam dedocendi esse videantur. Quodcumque in mentem incideret, et quodcumque tamquam occurreret. Inquit, dasne adolescenti veniam? Et quidem, inquit, vehementer errat; </p>
            </div>
        </div>

        <!-- fileinfos -->
        <div id="fileInfosModal" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="FileInfosLabel" aria-hidden="true">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
            <h3 id="myModalLabel">Dokumenteneigenschaften</h3>
          </div>
          <div class="modal-body">
            <table class="table table-bordered table-striped">
                <tbody class="table-hover">
                    <tr>
                        <th class="span2">Name</th>
                        <td>{{info.title}}</td>
                        <td class="change span1"><button class="btn btn-primary"><i class="icon-cog icon-white"></i></button></td>
                    </tr>
                    <tr>
                        <th class="span2">Dateiname</th>
                        <td>{{info.filename}}</td>
                        <td class="change span1"><button class="btn btn-primary"><i class="icon-cog icon-white"></i></button></td>
                    </tr>
                    <tr>
                        <th class="span2">Speicherort</th>
                        <td>{{info.path}}</td>
                        <td></td>
                    </tr>
                    <tr>
                        <th class="span2">Revision</th>
                        <td>{{info.rev}}</td>
                        <td></td>
                    </tr>
                    <tr>
                        <th class="span2">Lokal vefügbar</th>
                        <td>nein</td>
                        <td><button class="btn btn-info"><i class="icon-arrow-down icon-white"></i></button></td>
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
                        <a class="brand" href="./index.html">mono:di</a>
                        <div class="nav-collapse collapse">
                            <ul class="nav">
                                <li>
                                    <div class="btn-group">
                                        <button class="btn btn-link dropdown-toggle" data-toggle="dropdown" ng-click="showView('main')">Dokument <span class="caret"></span></button>
                                        <ul class="dropdown-menu">
                                            <li><button class="btn btn-link" ng-click="saveDocument()">Save</button></li>
                                            <li><button class="btn btn-link" ng-click="showDocumentInfo()">Properties</button></li>
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
                    <h3>Passwort ändern</h3>
                </div>
                <form name="changePassword" ng-submit="changePass(pass)">
                    <div class="modal-body">
                        <p>
                            <input type="text" name="username" ng-model="pass.name" placeholder="Username" required="required" />
                            <span class="error" ng-show="changePassword.username.$error.required">!</span>
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
        <div id="annotationModal" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="ChangePasswordLabel" aria-hidden="true">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                <h3>Comment</h3>
            </div>
            <form name="changePassword" ng-submit="changePass(pass)">
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
                </div>
            </form>
        </div>

        <script src="/bundles/digitalwertmonodiclient/js/const.js"></script>
        <script src="/bundles/digitalwertmonodiclient/js/plugins.js"></script>
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

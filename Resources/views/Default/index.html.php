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
<!DOCTYPE html>
<html class="no-js" ng-app="monodi">
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
        <title>mono:di</title>
        <meta name="description" content="">
        <meta name="viewport" content="width=device-width">
        <?php foreach ($view['assetic']->stylesheets(
            array('@DigitalwertMonodiClientBundle/Resources/public/css/*'),
            array('cssrewrite')
        ) as $url): ?>
            <link rel="stylesheet" href="<?php echo $view->escape($url) ?>" />
        <?php endforeach; ?> 
            
        <?php foreach ($view['assetic']->javascripts(
            array(
                '@DigitalwertMonodiClientBundle/Resources/public/js/vendor/modernizr.js',
                '@DigitalwertMonodiClientBundle/Resources/public/js/vendor/angular.js',
                '@DigitalwertMonodiClientBundle/Resources/public/js/controllers.js',
                '@DigitalwertMonodiClientBundle/Resources/public/js/modules.js',
            )
        ) as $url): ?>
            <script src="<?php echo $view->escape($url) ?>"></script>
        <?php endforeach; ?>
        <?php /*
        <link rel="stylesheet" href="<?php echo $view['assets']->getPath('css/main.css') ?>">
        <script src="<?php echo $view['assets']->getUrl('js/vendor/modernizr.js') ?>"></script>
        <script src="<?php echo $view['assets']->getUrl('js/vendor/angular.js') ?>"></script>
        <script src="<?php echo $view['assets']->getUrl('js/controllers.js') ?>"></script>
        <script src="<?php echo $view['assets']->getUrl('js/modules.js') ?>"></script>         
         */
        ?>
    </head>
    <body>

        <div class="navbar navbar-inverse navbar-fixed-top">
            <div class="navbar-inner">
                <div class="container">
                    <button type="button" class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                    </button>
                    <a class="brand" href="./">mono:di</a>
                    <div class="nav-collapse collapse">
                        <ul class="nav">
                            <li>
                                <div class="btn-group">
                                    <button class="btn btn-link dropdown-toggle" data-toggle="dropdown">Dokument <span class="caret"></span></button>
                                    <ul class="dropdown-menu">
                                        <li><button class="btn btn-link">Speichern</button></li>
                                        <li><button class="btn btn-link">Speichern unter</button></li>
                                        <li><button class="btn btn-link">Eigenschaften</button></li>
                                        <li class="divider"></li>
                                        <li><button class="btn btn-link">Neu</button></li>
                                        <li><button class="open btn btn-link">Öffnen</button></li>
                                    </ul>
                                </div>
                            </li>
                            <li><button class="filecontrol btn btn-link">Verwaltung</button></li>
                            <li class="right"><button class="help btn btn-link">Hilfe</button></li>
                            <li class="right"><button class="btn btn-link" data-target="#changePass" data-toggle="modal">Profil</button></li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>

        <div class="views">
            <div class="main container">
                <img src="<?php echo $view['assets']->getUrl($bundleAssetPath . 'img/placeholder.gif') ?>" alt="placeholder">
            </div>

            <div class="files container" ng-controller="DocumentListCtrl">
                <div class="row">
                    <div class="fileviewToggle btn-group span4 offset8">
                        <button class="btn active"><i class="icon-align-left"></i> Ordnerstruktur</button>
                        <button class="btn"><i class="icon-th-list"></i> Reine Liste</button>
                    </div>


                    <div class="batch btn-group span4">
                        <button class="btn dropdown-toggle btn-block" data-toggle="dropdown">Batchfunktionen <span class="caret"></span></button>
                        <ul class="dropdown-menu">
                            <li><button class="btn btn-link">Drucken</button></li>
                            <li><button class="btn btn-link">Löschen</button></li>
                            <li><button class="btn btn-link">Lokal speichern</button></li>
                            <li><button class="btn btn-link">Lokal löschen</button></li>
                        </ul>
                    </div>

                    <div class="fileviews">
                        <div class="fileStructure clearfix">
                            <ul>
                                <li><button class="btn btn-link"><i class="icon-folder-close"></i> Band 1</button>
                                    <ul>
                                        <li><button class="btn btn-link"><i class="icon-folder-close"></i> Aachen</button>
                                            <ul>
                                                <li><button class="btn btn-link"><i class="icon-folder-close"></i> Aa13</button>
                                                    <ul>
                                                        <li>
                                                            <input type="checkbox"><button class="btn btn-link">Dokument 1</button>
                                                            <div class="actions btn-group">
                                                                <button class="btn btn-danger"><i class="icon-trash icon-white"></i></button>
                                                                <button class="btn btn-inverse"><i class="icon-print icon-white"></i></button>
                                                                <button class="btn btn-info"><i class="icon-arrow-down icon-white"></i></button>
                                                                <button class="btn btn-primary" data-target="#fileInfos" data-toggle="modal"><i class="icon-info-sign icon-white"></i></button>
                                                            </div>
                                                        </li>
                                                        <li>
                                                            <input type="checkbox"><button class="btn btn-link">Dokument 2</button>
                                                            <div class="actions btn-group">
                                                                <button class="btn btn-danger"><i class="icon-trash icon-white"></i></button>
                                                                <button class="btn btn-inverse"><i class="icon-print icon-white"></i></button>
                                                                <button class="btn btn-warning"><i class="icon-remove icon-white"></i></button>
                                                                <button class="btn btn-primary"><i class="icon-info-sign icon-white"></i></button>
                                                        </li>
                                                    </ul>
                                                </li>
                                                <li><button class="btn btn-link"><i class="icon-folder-close"></i> Aa16</button></li>
                                            </ul>
                                        </li>
                                        <li><button class="btn btn-link"><i class="icon-folder-close"></i> Trier</button></li>
                                    </ul>
                                </li>
                                <li><button class="btn btn-link"><i class="icon-folder-close"></i> Band 2</button></li>
                            </ul>
                        </div>

                        <div class="fileList clearfix">
                            <table class="table table-bordered table-striped span12">
                                <thead>
                                <th class="span1"><input type="checkbox"></th>
                                <th class="span6">Struktur</th>
                                <th class="span4">Name</th>
                                <th>Funktionen</th>
                                </thead>
                                <tbody class="table-hover">
                                    <tr ng-repeat="document in documents">
                                        <td><input type="checkbox" name="{{document.id}}"></td>
                                        <td>{{document.filename|formatPath}}</td>
                                        <td>{{document.filename|formatName}}</td>
                                        <td>
                                            <div class="actions btn-group">
                                                <button class="btn btn-danger"><i class="icon-trash icon-white"></i></button>
                                                <button class="btn btn-inverse"><i class="icon-print icon-white"></i></button>
                                                <button class="btn btn-info"><i class="icon-arrow-down icon-white"></i></button>
                                                <button class="btn btn-primary" data-target="#fileInfos" data-toggle="modal"><i class="icon-info-sign icon-white"></i></button>
                                            </div>
                                        </td>
                                    </tr>
                                    <!--<tr>
                                        <td><input type="checkbox"></td>
                                        <td>Band 1 - Aachen - Aa13</td>
                                        <td>Dokument 1</td>
                                        <td>
                                            <div class="actions btn-group">
                                                <button class="btn btn-danger"><i class="icon-trash icon-white"></i></button>
                                                <button class="btn btn-inverse"><i class="icon-print icon-white"></i></button>
                                                <button class="btn btn-info"><i class="icon-arrow-down icon-white"></i></button>
                                                <button class="btn btn-primary" data-target="#fileInfos" data-toggle="modal"><i class="icon-info-sign icon-white"></i></button>
                                            </div>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td><input type="checkbox"></td>
                                        <td>Band 1 - Aachen - Aa13</td>
                                        <td>Dokument 2</td>
                                        <td>
                                            <div class="actions btn-group">
                                                <button class="btn btn-danger"><i class="icon-trash icon-white"></i></button>
                                                <button class="btn btn-inverse"><i class="icon-print icon-white"></i></button>
                                                <button class="btn btn-warning"><i class="icon-remove icon-white"></i></button>
                                                <button class="btn btn-primary"><i class="icon-info-sign icon-white"></i></button>
                                            </div>
                                        </td>
                                    </tr>-->
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

        <!-- login -->
        <div id="login" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="LoginLabel" aria-hidden="true">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                <h3 id="myModalLabel">Login</h3>
            </div>
            <div class="modal-body">
                <p><input type="text" id="loginname" placeholder="Benutzername"></p>
                <p><input type="password" id="loginpass" placeholder="Passwort"></p>
            </div>
            <div class="modal-footer">
                <button class="btn forgot" data-dismiss="modal" aria-hidden="true">Passwort vergessen</button>
                <button class="btn btn-primary">Anmelden</button>
            </div>
        </div>

        <!-- login -->
        <div id="forgot" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="LoginLabel" aria-hidden="true">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                <h3 id="myModalLabel">Passwort vergessen?</h3>
            </div>
            <div class="modal-body">
                <p><input type="text" id="loginname" placeholder="Benutzername"></p>
            </div>
            <div class="modal-footer">
                <button class="btn btn-primary">Neues Passwort anfordern</button>
            </div>
        </div>

        <!-- change password -->
        <div id="changePass" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="ChangePasswordLabel" aria-hidden="true">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                <h3 id="myModalLabel">Passwort ändern</h3>
            </div>
            <div class="modal-body">
                <p><input type="password" id="login" placeholder="bisheriges Passwort"></p>
                <hr>
                <p><input type="password" id="new" placeholder="Passwort"></p>
                <p><input type="password" id="newR" placeholder="Passwort"></p>
            </div>
            <div class="modal-footer">
                <button class="btn btn-primary">Passwort ändern</button>
            </div>
        </div>

        <!-- fileinfos -->
        <div id="fileInfos" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="FileInfosLabel" aria-hidden="true">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                <h3 id="myModalLabel">Dokumenteneigenschaften</h3>
            </div>
            <div class="modal-body">
                <table class="table table-bordered table-striped">
                    <tbody class="table-hover">
                        <tr>
                            <th class="span2">Name</th>
                            <td>Dokument 1</td>
                            <td class="change span1"><button class="btn btn-primary"><i class="icon-cog icon-white"></i></button></td>
                        </tr>
                        <tr>
                            <th class="span2">Speicherort</th>
                            <td>Band 1 - Aachen - Aa13</td>
                            <td class="change span1"><button class="btn btn-primary"><i class="icon-cog icon-white"></i></button></td>
                        </tr>
                        <tr>
                            <th class="span2">Erstellt am</th>
                            <td>08.03.2013</td>
                            <td></td>
                        </tr>
                        <tr>
                            <th class="span2">Letztmals bearbeitet am</th>
                            <td>08.03.2013</td>
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

        <!--<script src="//ajax.googleapis.com/ajax/libs/jquery/1.9.0/jquery.min.js"></script>-->
        <script>window.jQuery || document.write('<script src="<?php echo $view['assets']->getUrl($bundleAssetPath . 'js/vendor/jquery.js') ?>"><\/script>')</script>
        <?php foreach ($view['assetic']->javascripts(
            array(
                '@DigitalwertMonodiClientBundle/Resources/public/js/plugins.js',
                '@DigitalwertMonodiClientBundle/Resources/public/js/main.js',
            )
        ) as $url): ?>
            <script src="<?php echo $view->escape($url) ?>"></script>
        <?php endforeach; ?>
        <?php /*
        <script src="<?php echo $view['assets']->getUrl('js/plugins.js') ?>"></script>
        <script src="<?php echo $view['assets']->getUrl('js/main.js') ?>"></script>
        */ ?>
        <!-- Google Analytics: change UA-XXXXX-X to be your site's ID.
        <script>
                var _gaq=[['_setAccount','UA-XXXXX-X'],['_trackPageview']];
                (function(d,t){var g=d.createElement(t),s=d.getElementsByTagName(t)[0];
                g.src=('https:'==location.protocol?'//ssl':'//www')+'.google-analytics.com/ga.js';
                s.parentNode.insertBefore(g,s)}(document,'script'));-->
    </script>
</body>
</html>

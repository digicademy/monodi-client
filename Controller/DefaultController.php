<?php

namespace Digitalwert\Symfony2\Bundle\Monodi\ClientBundle\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\Controller;
use Sensio\Bundle\FrameworkExtraBundle\Configuration\Route;
use Sensio\Bundle\FrameworkExtraBundle\Configuration\Template;

class DefaultController extends Controller
{
    /**
     * @Route("/")
     * @Template(engine="php")
     */
    public function indexAction()
    {
        return array();
    }
}

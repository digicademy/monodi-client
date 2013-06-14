<?php

namespace Digitalwert\Symfony2\Bundle\Monodi\ClientBundle\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\Controller;
use Sensio\Bundle\FrameworkExtraBundle\Configuration\Route;
use Sensio\Bundle\FrameworkExtraBundle\Configuration\Template;
use JMS\DiExtraBundle\Annotation as DI;


class DefaultController extends Controller
{
    /**
     * @DI\Inject("fos_oauth_server.client_manager.default")
     * @var \FOS\OAuthServerBundle\Entity\ClientManager
     */
    protected $clientManager;
    
    /**
     * @Route("/")
     * @Template(engine="php")
     */
    public function indexAction()
    {
        
        /**  \Digitalwert\Symfony2\Bundle\Monodi\OAuthServerBundle\Entity\Client */
        $client = $this->clientManager->findClientBy(array('name' => 'MonodiClient'));
        if(!$client) {
           throw new \RuntimeException('No Public-Id found for client');            
        }
        $publicId = $client->getPublicId();
        
        
        $response = $this->render(
            'DigitalwertMonodiClientBundle:Default:index.xhtml.php',
            array(
                'publicId' => $publicId
            )
        );
        
        $response->headers->set('Content-Type', 'application/xhtml+xml');

        return $response;
    }
}

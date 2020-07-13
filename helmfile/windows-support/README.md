## purpose

this is needed because helmfile didn't work properly for me on windows (the helm diff plugin), as well as helmfile docker files and helmfile make. hence this dockerfile that works on windows. I needed to include compiled helmfile for the same reason.

Build this dockerfile like you normally would and after that you can just use the docker image to run helmfile. The provided dockerfile has got aws cli, kubectl, terraform, helm, helm plugins and helmfile.
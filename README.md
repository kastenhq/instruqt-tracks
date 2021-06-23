# Kasten K10 Instruqt Tracks

[Kasten tracks](https://play.instruqt.com/kasten)

[Instruqt Docs](https://docs.instruqt.com/)

The primary lab (available as “Free K10”) is the [k10-testdrive](https://play.instruqt.com/kasten/tracks/k10-testdrive).

## Instruqt cli
[Guide: SDK](https://docs.instruqt.com/reference/software-development-kit-sdk)

Download and install from [here](https://github.com/instruqt/cli/releases)

authenticate via:

```bash
$ instruqt auth login
==> Signing in to instruqt
==> Please open the following address in your browser and
    sign in with your Instruqt credentials:
==> <http://localhost:15777/>
==> Storing credentials
    OK
```

## Updating Tracks from Instruqt
### Pull
Instruqt prefers to be the source of truth, on top of that, if marketing makes any changes - those will be in instruqt and not in the code repo, as such pull updates from instruqt before any changes

```bash
cd k10/demos/instruqt/k10-testdrive
instruqt track pull --force
```

### Test
To test changes run the following command

```bash
instruqt track test kasten/<slug-name>
```

### Push
Once the track has been updated and tested, make changes and submit to instruqt first - this will update the track checksum from instruqt before submitting to the git repo.

```bash
instruqt track push
```

after this is done then submit the PR via github.

## Create a new track
### Clone track
[Guide: How to copy an existing track](https://docs.instruqt.com/reference/software-development-kit-sdk/how-to-copy-an-existing-track)

Often times the marketing team would like to use the same lab, just for a different campaign. To do so, you can use an existing track to clone, and create a new track.

```bash
instruqt track create --from kasten/<source-slug-name> --title Kasten Kubernetes Lab --slug kasten/<destination-slug-name>
```

### Create from scratch
To create a barebone track use the following command

```bash
instruqt track create --title "<New Track Name>" --slug kasten/<slug-name>
```

Again, to save changes, submit to instruqt first, then submit PR through github

## Base Image
[Guides: Custom images](https://docs.instruqt.com/sandbox-environment/custom-images#how-to-use-custom-virtual-machine-images)

[Guides: Managing access to custom images](https://cloud.google.com/compute/docs/images/managing-access-custom-images#share-images-between-organization)

Instruqt uses a custom image stored on GCP. The image is not automatically created, it is a relic of a VM that is being updated manually as needed.

## Build new image:
First start the `instruqt-baseimage` found at [https://console.cloud.google.com/compute/instancesDetail/zones/europe-west1-b/instances/instruqt-baseimage?project=k10-gke-testdrive-180621&rif_reserved](https://console.cloud.google.com/compute/instancesDetail/zones/europe-west1-b/instances/instruqt-baseimage?project=k10-gke-testdrive-180621&rif_reserved)

The base image setup script is found in the git repo gke_base_image_setup.sh which should be followed if needed to completely rebuild.

Once started you will likely need to stop and restart the kind server

```bash
kind delete server --name k10
```

To restart you’ll need to follow the base image setup starting at the `kind create server...` in order to rebuild the kind cluster. [https://github.com/kastenhq/k10/blob/master/demos/instruqt/gke_base_image_setup.sh#L49](https://github.com/kastenhq/k10/blob/master/demos/instruqt/gke_base_image_setup.sh#L49)

If any other changes are made to the image, please add those changes to the `gke_base_image_setup.sh` file for future reference.

Once your changes are completed to the image, shut the image down, and create a new VM image: [https://console.cloud.google.com/compute/imagesAdd?project=k10-gke-testdrive-180621&rif_reserved](https://console.cloud.google.com/compute/imagesAdd?project=k10-gke-testdrive-180621&rif_reserved) be sure to set:

- **Source Image:** `instruqt-baseimage`
- **Location:** Multi-region - EU (instruqt is a European based company, as such we provide the image in that region to reduce latency
- **Name:** (as defined - current template: `instruqt-k8s-testdrive-<year>`)

Finally the permissions will need to be changed to add the instruqt account to the image as a compute image user. From the list of images, select the newly created image, and “Add Member” and paste in the following for the member `instruqt-track@instruqt-prod.iam.gserviceaccount.com` and the role should be: `Compute Engine > Compute Image User`.

The name chosen will need to be updated in all tracks using the previous image, you’ll need to update those tracks appropriately
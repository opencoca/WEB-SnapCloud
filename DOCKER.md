Setting Up and Building Multi-Architecture Images with Docker
=============================================================

### Building Multi-Architecture Images Using Docker Manifest

This guide explains how to build multi-architecture Docker images using the `docker manifest` command. Docker manifest is a reliable and original tool developed by Docker for creating multiarch images.

#### Steps:

1.  Building and Pushing Architecture-Specific Images

    First, build and push images for each architecture to Docker Hub using the following commands:

    -   For AMD64 Architecture:

        bashCopy code

        `docker build --platform linux/amd64 -t your-username/multiarch-example:manifest-amd64 --build-arg .
        docker push your-username/multiarch-example:manifest-amd64`

2.  Creating a Manifest List

    After building and pushing images for each architecture, create a manifest list that references all the images. Use the `docker manifest create` command:

    bashCopy code

    `docker manifest create your-username/multiarch-example:manifest-latest\
    --amend your-username/multiarch-example:manifest-amd64\
    ... Add additional tagged images as needed

3.  Pushing the Manifest List to Docker Hub

    Finally, push the created manifest list to Docker Hub:

    bashCopy code

    `docker manifest push your-username/multiarch-example:manifest-latest`

    After pushing, you can view the new tag on Docker Hub, which references all the architecture-specific images.

*Note: Replace `your-username` with your actual Docker Hub username.*
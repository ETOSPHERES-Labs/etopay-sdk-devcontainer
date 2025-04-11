# ETOPAY SDK Devcontainer

[![CI](https://github.com/ETOSPHERES-Labs/etopay-sdk-devcontainer/actions/workflows/build_container.yml/badge.svg)](https://github.com/ETOSPHERES-Labs/etopay-sdk-devcontainer/actions/workflows/build_container.yml)

This repository contains the development environment setup for the ETOPAY SDK using a **Devcontainer**. It leverages Docker to provide a consistent and isolated development environment for building, testing, and deploying the [ETOPAY SDK](https://github.com/ETOSPHERES-Labs/etopay-sdk).

## Features

- Pre-configured environment for **Rust**, **Node.js**, **Android**, and **Swift** development.
- Includes tools like `rustup`, `cargo`, `bun`, `gradle`, and Android SDK/NDK.
- Supports cross-compilation for multiple platforms, including Android and iOS.
- Integrated with GitHub Actions for building and pushing Docker images to GitHub Container Registry (GHCR).

## Getting Started

### Prerequisites

- Install [Docker](https://www.docker.com/).
- Install [Visual Studio Code](https://code.visualstudio.com/) with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).

### Usage

1. Clone the ETOPay SDK repository:

   ```bash
   git clone https://github.com/ETOSPHERES-Labs/etopay-sdk
   cd etopay-sdk
   ```

2. Open the ETOPay SDK repository in Visual Studio Code.

3. Reopen the folder in the Devcontainer:
   - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS) and select **Reopen in Container**.

4. Start developing in the pre-configured environment.

### Building the Docker Image

To build the Docker image locally:

```bash
git clone https://github.com/ETOSPHERES-Labs/etopay-sdk-devcontainer && cd etopay-sdk-devcontainer
docker build -t etopay-sdk-devcontainer .
```

### Running the Container

To run the container:

```bash
docker run -it etopay-sdk-devcontainer
```

## GitHub Actions Workflow

This repository includes a GitHub Actions workflow to automate the building and pushing of the Docker image to GitHub Container Registry (GHCR).

### Workflow Behavior

- **Manual Trigger**: Pushes the image with the branch name as the tag if triggered on a `feat/*` branch.
- **Push to `main`**: Pushes the image with the `latest` tag.
- **Git Tag**: Pushes the image with the Git tag as the tag.

### Running the Workflow

1. Go to the **Actions** tab in your GitHub repository.
2. Select the **Build and Push Devcontainer** workflow.
3. Trigger the workflow manually or by pushing to `main` or creating a Git tag.

## License

This project is licensed under the [GNU Affero General Public License v3.0](LICENSE).

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

## Support

For any questions or issues, please contact the [maintainers](mailto:lobster@etospheres.com) or open an issue in this repository.

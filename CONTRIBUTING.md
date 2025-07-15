# Contributing to SwarmContainer

Thank you for your interest in contributing to SwarmContainer! We welcome contributions from the community.

## How to Contribute

### Reporting Issues
- Check if the issue already exists
- Include steps to reproduce
- Include your environment details (OS, Docker version, VS Code version)
- Include relevant logs from the container

### Suggesting Features
- Check if the feature has already been suggested
- Explain the use case and benefits
- Consider how it fits with the project's goals

### Submitting Pull Requests

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the existing code style
   - Add tests if applicable
   - Update documentation

4. **Test your changes**
   ```bash
   # Run the test suite
   ./.devcontainer/scripts/tests/test-devcontainer.sh
   ```

5. **Commit your changes**
   ```bash
   git commit -m "feat: add amazing feature"
   ```
   
   Follow [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat:` New feature
   - `fix:` Bug fix
   - `docs:` Documentation changes
   - `test:` Test additions or changes
   - `chore:` Maintenance tasks

6. **Push and create a PR**
   ```bash
   git push origin feature/your-feature-name
   ```

### Code Guidelines

- **Shell Scripts**: Use bash and follow POSIX conventions where possible
- **Documentation**: Update README.md and other docs as needed
- **Security**: Never commit secrets or reduce security defaults
- **Testing**: Add tests for new features

### Development Setup

1. Clone the repository
2. Open in VS Code
3. Reopen in Container when prompted
4. Make your changes
5. Test inside the container

### Questions?

Feel free to open an issue for discussion or clarification.
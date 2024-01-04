# Use an official Swift runtime as a base image
FROM swift:latest

# Set the working directory inside the container
WORKDIR /app

# Copy the entire project into the container
COPY . .

# Build the Swift project
RUN swift build --target Blocks

# Run the tests
CMD ["swift", "test"]

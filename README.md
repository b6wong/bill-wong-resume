# Bill Wong Resume

This uses [JSON Resume](https://jsonresume.org/) to generate my resume.

[resume-cli](https://github.com/jsonresume/resume-cli#readme) has simple instructions to get started.

## Running Locally

You can start a web server that serves the resume locally.

Install the command-line tool:

`npm install -g resume-cli`

Create your resume.json, or you can generate a sample file:

`resume init`

Generate an html version of the resume and serve it locally

`resume serve --port 3000 --theme flat`
`resume serve --port 3000 --theme onepage`

## Infrastructure

The infrastructure will be maintained by Terraform in the [terraform-aws](https://github.com/b6wong/terraform-aws) repository

## CI/CD

Using GitHub Actions

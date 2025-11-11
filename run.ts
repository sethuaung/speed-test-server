import { Vercel } from '@vercel/sdk';

const vercel = new Vercel({
  bearerToken: process.env.VERCEL_TOKEN,
});
const projectName = 'speed-test-server'; //The project name used in the deployment URL

async function addAndListEnvVars() {
  try {
    // Add new environment variables
    const addResponse = await vercel.projects.createProjectEnv({
      idOrName: projectName,
      upsert: 'true',
      requestBody: [
        {
          key: 'API_KEY',
          value: 'secret_value',
          target: ['production', 'preview'],
          type: 'encrypted',
        },
        {
          key: 'DEBUG',
          value: 'true',
          target: ['development'],
          type: 'plain',
        },
      ],
    });
    console.log(
      'Added environment variables:',
      JSON.stringify(addResponse, null, 2),
    );
  } catch (error) {
    console.error(
      error instanceof Error ? `Error: ${error.message}` : String(error),
    );
  }
}

addAndListEnvVars();

using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Primitives;
using Microsoft.Rest;
using Microsoft.Azure.Management.ResourceManager;
using Microsoft.Azure.Management.DataFactory;
using Microsoft.Azure.Management.DataFactory.Models;
using Microsoft.IdentityModel.Clients.ActiveDirectory;

public static async Task<IActionResult> Run(HttpRequest req, ILogger log)
{
    log.LogInformation("Start TriggerPipeline()");

    string subscriptionId = "";
    string tenantId = "";
    string applicationId = "";
    string authenticationKey = "";

    string resourceGroup = "";
    string dataFactoryName = "";
    string pipelineName = "";

    // Authenticate and create a data factory management client
    var context = new AuthenticationContext("https://login.windows.net/" + tenantId);
    ClientCredential cc = new ClientCredential(applicationId, authenticationKey);
    AuthenticationResult result = context.AcquireTokenAsync("https://management.azure.com/", cc).Result;
    ServiceClientCredentials cred = new TokenCredentials(result.AccessToken);
    var client = new DataFactoryManagementClient(cred) { SubscriptionId = subscriptionId };

    await client.Pipelines.CreateRunWithHttpMessagesAsync(resourceGroup, dataFactoryName, pipelineName, null);

    // BadRequestObjectResult on failure
    return new OkObjectResult("That worked!");
}

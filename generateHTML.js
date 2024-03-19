// generateHTML.js

const fs = require('fs');
const yaml = require('js-yaml');

// Load the YAML data
const jsonData = JSON.parse(fs.readFileSync('QA-Unitrac.json', 'utf8'));

// Extract the "Name" and "Status" fields from each "TestCaseExecution"
const rows = jsonData.TestSetExecutions[0].TestCaseExecutions.map(testCase => ({
    Name: testCase.Name,
    Status: testCase.Status
}));

// Create HTML content
const htmlContent = `
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Test Case Names and Status</title>
<style>
table {
    border-collapse: collapse;
    width: 100%;
}

th, td {
    border: 1px solid #dddddd;
    text-align: left;
    padding: 8px;
}

th {
    background-color: #f2f2f2;
}
</style>
</head>
<body>

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Status</th>
    </tr>
  </thead>
  <tbody>
    ${rows.map(row => `
    <tr>
      <td>${row.Name}</td>
      <td>${row.Status}</td>
    </tr>
    `).join('')}
  </tbody>
</table>

</body>
</html>
`;

// Write HTML content to a file
fs.writeFileSync('output.html', htmlContent);

console.log('HTML file generated: output.html');

const express = require('express')
const fs = require('fs')
const app = express()

app.get('/:playerName/', (request, response) => {
  const { playerName } = request.params
  console.log('Serving', playerName)
  fs.createReadStream('player/' + playerName + '/index.html').pipe(response)
})

app.listen(80, () => {
  console.log('Listening on port 80')
})

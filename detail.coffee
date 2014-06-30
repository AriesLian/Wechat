Haoys = require './doctor'
 
exports.get_score = (req, res) ->
  ic_code = req.params.ic_code
  year = req.params.year
  Haoys.find {ic_code: ic_code,year: year}, (err, result) ->
    res.render 'cme',
      result: result

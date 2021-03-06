new Rule
  condition: $('#shifts-data').length
  load: ->
    @map.changeTotalAmount ||= ->
      input_val = $(this).val()
      row = $(this).parents('tr:first')
      payShiftsLink = row.find('a[data-pay-shifts-button]')

      earn = parseFloat row.find('span[data-earns]').data('earns')
      credit = parseFloat row.find('span[data-upfronts]').data('upfronts')
      to_pay = earn + credit

      if  to_pay != input_val
        futureUpfront = (input_val - to_pay).toFixed(2)
        linkHref = payShiftsLink.attr('href')
        updatedUrl = linkHref
          .replace(/upfronts=-?\d+(\.\d*)?/, "upfronts=#{futureUpfront}")
          .replace(/total_to_pay=-?\d+(\.\d*)?/, "total_to_pay=#{input_val}")

        payShiftsLink.attr('href', updatedUrl)

    @map.sendPay ||= (e,a,b)->
      if e.which == 13
        e.preventDefault()
        $(this).parents('tr:first').find('a[data-pay-shifts-button]').click()


    $(document).on 'change keyup', '[data-to-pay-total]', @map.changeTotalAmount
    $(document).on 'keydown', '[data-to-pay-total]', @map.sendPay

  unload: ->
    $(document).off 'change keyup', '[data-to-pay-total]', @map.changeTotalAmount

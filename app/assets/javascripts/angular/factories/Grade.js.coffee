@gradecraft.factory 'Grade', ['$http', 'EventHelper', ($http, EventHelper)->
  class Grade
    constructor: (attrs={}, http)->
      @id = attrs.id
      @status = attrs.status
      @raw_score = attrs.raw_score
      @feedback = attrs.feedback
      @is_custom_value = attrs.is_custom_value || false
      @student_id = attrs.student_id
      @assignment_id = attrs.assignment_id
      @releaseNecessary = attrs.assignment.release_necessary
      console.log("Release Necessary: #{@releaseNecessary}")
      @http = http
      @updated_at = null

    enableCustomValue: ()->
      console.log this.is_custom_value
      if this.is_custom_value == false
        this.is_custom_value = true
        this.update()

    disableCustomValue: ()->
      console.log this.is_custom_value
      if this.is_custom_value == true
        this.is_custom_value = false
        this.update()

    enableScoreLevels: (event)->
      EventHelper.killEvent(event)
      if this.is_custom_value == true
        this.is_custom_value = false
        this.update()

    justUpdated: ()->
      this.timeSinceUpdate() < 1000

    timeSinceUpdate: ()->
      self = this
      Math.abs(new Date() - self.updated_at)
 
    modelOptions: ()->
      {
        updateOn: 'default blur',
        debounce: {
          default: 1800,
          blur: 0
        }
      }

    # updating grade properties
    update: ()->
      if this.releaseNecessary
        self = this
        @http.put("/grades/#{self.id}/async_update", self).success(
          (data,status)->
            self.updated_at = new Date()
        )
        .error((err)->
        )

    params: ()->
      {
        id: self.id,
        raw_score: this.raw_score,
        feedback: this.feedback,
        is_custom_value: this.is_custom_value
      }

]

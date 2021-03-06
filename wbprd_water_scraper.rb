require 'rubygems'
require 'httparty'
#require ''

#http://72.26.224.173/water/Default.aspx

class Wbprd
  include HTTParty
  #format :html
  http_proxy '10.20.0.1', 8080
  
  #application/x-www-form-urlencoded
  #hdShortOrder => 'DESC',
  #:hfID => 'hfID',
  #:hfMode => 'hfMode',
  
  #top level, nothing selected:
  #/wEPDwUJNTI1NzY5NDcyD2QWAgIDD2QWFAIfDw8WBB4EVGV4dAUPQ29udGFpbiBTZWFyY2g6HgdWaXNpYmxlZ2RkAiEPEA8WAh8BZ2RkZGQCLQ8QDxYGHg1EYXRhVGV4dEZpZWxkBQ1EaXN0cmljdF9OYW1lHg5EYXRhVmFsdWVGaWVsZAUNRGlzdHJpY3RfQ29kZR4LXyFEYXRhQm91bmRnZBAVFAZTRUxFQ1QjQmFua3VyYSAgICAgICAgICAgICAgICAgICAgICAgIFswMV0jQnVyZHdhbiAgICAgICAgICAgICAgICAgICAgICAgIFswMl0jQmlyYmh1bSAgICAgICAgICAgICAgICAgICAgICAgIFswM10jRGFyamVlbGluZyAgICAgICAgICAgICAgICAgICAgIFswNF0jSG93cmFoICAgICAgICAgICAgICAgICAgICAgICAgIFswNV0jSG9vZ2hseSAgICAgICAgICAgICAgICAgICAgICAgIFswNl0jSmFscGFpZ3VyaSAgICAgICAgICAgICAgICAgICAgIFswN10jQ29vY2hiZWhhciAgICAgICAgICAgICAgICAgICAgIFswOF0jTWFsZGEgICAgICAgICAgICAgICAgICAgICAgICAgIFswOV0jUGFzY2hpbSBNaWRuYXBvcmUgICAgICAgICAgICAgIFsxMF0jUHVyYmEgTWlkbmFwb3JlICAgICAgICAgICAgICAgIFsxMV0jTXVyc2hpZGFiYWQgICAgICAgICAgICAgICAgICAgIFsxMl0jTmFkaWEgICAgICAgICAgICAgICAgICAgICAgICAgIFsxM10jUHVydWxpYSAgICAgICAgICAgICAgICAgICAgICAgIFsxNF0jTm9ydGggMjQtUGFyZ2FuYXMgICAgICAgICAgICAgIFsxNV0jU291dGggMjQtUGFyZ2FuYXMgICAgICAgICAgICAgIFsxNl0jRGFrc2hpbiBEaW5hanB1ciAgICAgICAgICAgICAgIFsxN10jVXR0YXIgRGluYWpwdXIgICAgICAgICAgICAgICAgIFsxOF0jS29sa2F0YSAgICAgICAgICAgICAgICAgICAgICAgIFsxOV0VFAEwAjAxAjAyAjAzAjA0AjA1AjA2AjA3AjA4AjA5AjEwAjExAjEyAjEzAjE0AjE1AjE2AjE3AjE4AjE5FCsDFGdnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnFgFmZAIxDxAPFggfAgUKQkxPQ0tfTkFNRR8DBQpCTE9DS19DT0RFHwRnHgdFbmFibGVkZ2QQFQEDQUxMFQEAFCsDAWcWAWZkAjMPDxYEHwAFC1BhbmNoYXlhdCA6HwFoZGQCNQ8QDxYKHwIFB0dQX05BTUUfAwUHR1BfQ09ERR8EZx8BaB8FaGQQFQAVABQrAwAWAGQCNw8PFgQfAAUHTW91emEgOh8BaGRkAjkPEA8WCB8CBQtFTkdfTU9VTkFNRR8DBQdtb3Vjb2RlHwRnHwFoZBAVABUAFCsDABYAZAI7DxAPFgIfAWdkZBYBZmQCPw88KwALAgAPFgoeC18hSXRlbUNvdW50Zh4IRGF0YUtleXMWAB8BaB4JUGFnZUNvdW50AgEeFV8hRGF0YVNvdXJjZUl0ZW1Db3VudGZkATwrABQCAzwrAAQBABYCHwFnBDwrAAQBABYCHwFoZGR/u9mK2BOq0HHWP5gKuP0KvXCJ3A==
  
  #district 1 selected:
  #/wEPDwUJNTI1NzY5NDcyD2QWAgIDD2QWFAIfDw8WAh4HVmlzaWJsZWdkZAIhDxAPFgIfAGdkZGRkAi0PEA8WBh4NRGF0YVRleHRGaWVsZAUNRGlzdHJpY3RfTmFtZR4ORGF0YVZhbHVlRmllbGQFDURpc3RyaWN0X0NvZGUeC18hRGF0YUJvdW5kZ2QQFRQGU0VMRUNUI0Jhbmt1cmEgICAgICAgICAgICAgICAgICAgICAgICBbMDFdI0J1cmR3YW4gICAgICAgICAgICAgICAgICAgICAgICBbMDJdI0JpcmJodW0gICAgICAgICAgICAgICAgICAgICAgICBbMDNdI0RhcmplZWxpbmcgICAgICAgICAgICAgICAgICAgICBbMDRdI0hvd3JhaCAgICAgICAgICAgICAgICAgICAgICAgICBbMDVdI0hvb2dobHkgICAgICAgICAgICAgICAgICAgICAgICBbMDZdI0phbHBhaWd1cmkgICAgICAgICAgICAgICAgICAgICBbMDddI0Nvb2NoYmVoYXIgICAgICAgICAgICAgICAgICAgICBbMDhdI01hbGRhICAgICAgICAgICAgICAgICAgICAgICAgICBbMDldI1Bhc2NoaW0gTWlkbmFwb3JlICAgICAgICAgICAgICBbMTBdI1B1cmJhIE1pZG5hcG9yZSAgICAgICAgICAgICAgICBbMTFdI011cnNoaWRhYmFkICAgICAgICAgICAgICAgICAgICBbMTJdI05hZGlhICAgICAgICAgICAgICAgICAgICAgICAgICBbMTNdI1B1cnVsaWEgICAgICAgICAgICAgICAgICAgICAgICBbMTRdI05vcnRoIDI0LVBhcmdhbmFzICAgICAgICAgICAgICBbMTVdI1NvdXRoIDI0LVBhcmdhbmFzICAgICAgICAgICAgICBbMTZdI0Rha3NoaW4gRGluYWpwdXIgICAgICAgICAgICAgICBbMTddI1V0dGFyIERpbmFqcHVyICAgICAgICAgICAgICAgICBbMThdI0tvbGthdGEgICAgICAgICAgICAgICAgICAgICAgICBbMTldFRQBMAIwMQIwMgIwMwIwNAIwNQIwNgIwNwIwOAIwOQIxMAIxMQIxMgIxMwIxNAIxNQIxNgIxNwIxOAIxORQrAxRnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZxYBAgFkAjEPEA8WCB8BBQpCTE9DS19OQU1FHwIFCkJMT0NLX0NPREUfA2ceB0VuYWJsZWRnZBAVFwNBTEwOQkFOS1VSQS1JIFswMV0PQkFOS1VSQS1JSSBbMDJdDENISEFUTkEgWzAzXQ1TSEFMVE9SQSBbMDRdCk1FSklBIFswNV0SR0FOR0FKQUxHSEFUSSBbMDZdDEJBUkpPUkEgWzA3XQlPTkRBIFswOF0OVEFMREFOR1JBIFswOV0NU0lNTEFQQUwgWzEwXQtLSEFUUkEgWzExXQ1ISVJCQU5ESCBbMTJdC0lORFBVUiBbMTNdC1JBSVBVUiBbMTRdDFNBUkVOR0EgWzE1XQ5SQU5JQkFOREggWzE2XQ5CSVNITlVQVVIgWzE3XQtKT1lQVVIgWzE4XQ1LT1RVTFBVUiBbMTldDlNPTkFNVUtISSBbMjBdD1BBVFJBU0FZQVIgWzIxXQpJTkRBUyBbMjJdFRcAAjAxAjAyAjAzAjA0AjA1AjA2AjA3AjA4AjA5AjEwAjExAjEyAjEzAjE0AjE1AjE2AjE3AjE4AjE5AjIwAjIxAjIyFCsDF2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnFgFmZAIzDw8WBB4EVGV4dAULUGFuY2hheWF0IDofAGhkZAI1DxAPFggfAQUHR1BfTkFNRR8CBQdHUF9DT0RFHwNnHwBoZBAVABUAFCsDABYAZAI3Dw8WBB8FBQdNb3V6YSA6HwBoZGQCOQ8QDxYIHwEFC0VOR19NT1VOQU1FHwIFB21vdWNvZGUfA2cfAGhkEBUAFQAUKwMAFgBkAjsPEA8WAh8AaGRkFgBkAj8PPCsACwEADxYCHwBoZGRkyJKdBZ5eUs5HCRr2CxQdT/3enlw=
  
  #:submit => '' 
  #:ddlDistrict => '01', ddlBlock 
  def post(url)
    options = { :body => { 
      :__VIEWSTATE => '/wEPDwUJNTI1NzY5NDcyD2QWAgIDD2QWFAIfDw8WBB4EVGV4dAUPQ29udGFpbiBTZWFyY2g6HgdWaXNpYmxlZ2RkAiEPEA8WAh8BZ2RkZGQCLQ8QDxYGHg1EYXRhVGV4dEZpZWxkBQ1EaXN0cmljdF9OYW1lHg5EYXRhVmFsdWVGaWVsZAUNRGlzdHJpY3RfQ29kZR4LXyFEYXRhQm91bmRnZBAVFAZTRUxFQ1QjQmFua3VyYSAgICAgICAgICAgICAgICAgICAgICAgIFswMV0jQnVyZHdhbiAgICAgICAgICAgICAgICAgICAgICAgIFswMl0jQmlyYmh1bSAgICAgICAgICAgICAgICAgICAgICAgIFswM10jRGFyamVlbGluZyAgICAgICAgICAgICAgICAgICAgIFswNF0jSG93cmFoICAgICAgICAgICAgICAgICAgICAgICAgIFswNV0jSG9vZ2hseSAgICAgICAgICAgICAgICAgICAgICAgIFswNl0jSmFscGFpZ3VyaSAgICAgICAgICAgICAgICAgICAgIFswN10jQ29vY2hiZWhhciAgICAgICAgICAgICAgICAgICAgIFswOF0jTWFsZGEgICAgICAgICAgICAgICAgICAgICAgICAgIFswOV0jUGFzY2hpbSBNaWRuYXBvcmUgICAgICAgICAgICAgIFsxMF0jUHVyYmEgTWlkbmFwb3JlICAgICAgICAgICAgICAgIFsxMV0jTXVyc2hpZGFiYWQgICAgICAgICAgICAgICAgICAgIFsxMl0jTmFkaWEgICAgICAgICAgICAgICAgICAgICAgICAgIFsxM10jUHVydWxpYSAgICAgICAgICAgICAgICAgICAgICAgIFsxNF0jTm9ydGggMjQtUGFyZ2FuYXMgICAgICAgICAgICAgIFsxNV0jU291dGggMjQtUGFyZ2FuYXMgICAgICAgICAgICAgIFsxNl0jRGFrc2hpbiBEaW5hanB1ciAgICAgICAgICAgICAgIFsxN10jVXR0YXIgRGluYWpwdXIgICAgICAgICAgICAgICAgIFsxOF0jS29sa2F0YSAgICAgICAgICAgICAgICAgICAgICAgIFsxOV0VFAEwAjAxAjAyAjAzAjA0AjA1AjA2AjA3AjA4AjA5AjEwAjExAjEyAjEzAjE0AjE1AjE2AjE3AjE4AjE5FCsDFGdnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnFgFmZAIxDxAPFggfAgUKQkxPQ0tfTkFNRR8DBQpCTE9DS19DT0RFHwRnHgdFbmFibGVkZ2QQFQEDQUxMFQEAFCsDAWcWAWZkAjMPDxYEHwAFC1BhbmNoYXlhdCA6HwFoZGQCNQ8QDxYKHwIFB0dQX05BTUUfAwUHR1BfQ09ERR8EZx8BaB8FaGQQFQAVABQrAwAWAGQCNw8PFgQfAAUHTW91emEgOh8BaGRkAjkPEA8WCB8CBQtFTkdfTU9VTkFNRR8DBQdtb3Vjb2RlHwRnHwFoZBAVABUAFCsDABYAZAI7DxAPFgIfAWdkZBYBZmQCPw88KwALAgAPFgoeC18hSXRlbUNvdW50Zh4IRGF0YUtleXMWAB8BaB4JUGFnZUNvdW50AgEeFV8hRGF0YVNvdXJjZUl0ZW1Db3VudGZkATwrABQCAzwrAAQBABYCHwFnBDwrAAQBABYCHwFoZGR/u9mK2BOq0HHWP5gKuP0KvXCJ3A==',
      :__EVENTTARGET => 'ddlDistrict', 
      :__EVENTARGUMENT => ''
    }}
    self.class.post(url, options)
  end
end

puts Wbprd.new.post('http://72.26.224.173/water/Default.aspx')

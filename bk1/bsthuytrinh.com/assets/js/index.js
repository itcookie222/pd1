var timeRange = {
    '-1': 'Mặc định',
    0: '16h30 - 17h00',
    1: '17h00 - 17h30',
    2: '17h30 - 18h00',
    3: '18h00 - 18h30',
    4: '18h30 - 19h00',
    5: '19h00 - 19h30',
    6: '19h30 - 20h00',
    7: '20h00 - 20h30',
    8: 'Sau 20h30',
};

dayjs.extend(window.dayjs_plugin_relativeTime);

var iconObject = {
    'fa-sort-numeric-down':
        '<svg class="svg-inline--fa fa-sort-numeric-down fa-w-14" aria-hidden="true" focusable="false" data-prefix="fas" data-icon="sort-numeric-down" role="img" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512" data-fa-i2svg=""><path fill="currentColor" d="M304 96h16v64h-16a16 16 0 0 0-16 16v32a16 16 0 0 0 16 16h96a16 16 0 0 0 16-16v-32a16 16 0 0 0-16-16h-16V48a16 16 0 0 0-16-16h-48a16 16 0 0 0-14.29 8.83l-16 32A16 16 0 0 0 304 96zm26.15 162.91a79 79 0 0 0-55 54.17c-14.25 51.05 21.21 97.77 68.85 102.53a84.07 84.07 0 0 1-20.85 12.91c-7.57 3.4-10.8 12.47-8.18 20.34l9.9 20c2.87 8.63 12.53 13.49 20.9 9.91 58-24.76 86.25-61.61 86.25-132V336c-.02-51.21-48.4-91.34-101.85-77.09zM352 356a20 20 0 1 1 20-20 20 20 0 0 1-20 20zm-176-4h-48V48a16 16 0 0 0-16-16H80a16 16 0 0 0-16 16v304H16c-14.19 0-21.36 17.24-11.29 27.31l80 96a16 16 0 0 0 22.62 0l80-96C197.35 369.26 190.22 352 176 352z"></path></svg>',
    'fa-clock':
        '<svg class="svg-inline--fa fa-clock fa-w-16" aria-hidden="true" focusable="false" data-prefix="far" data-icon="clock" role="img" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" data-fa-i2svg=""><path fill="currentColor" d="M256 8C119 8 8 119 8 256s111 248 248 248 248-111 248-248S393 8 256 8zm0 448c-110.5 0-200-89.5-200-200S145.5 56 256 56s200 89.5 200 200-89.5 200-200 200zm61.8-104.4l-84.9-61.7c-3.1-2.3-4.9-5.9-4.9-9.7V116c0-6.6 5.4-12 12-12h32c6.6 0 12 5.4 12 12v141.7l66.8 48.6c5.4 3.9 6.5 11.4 2.6 16.8L334.6 349c-3.9 5.3-11.4 6.5-16.8 2.6z"></path></svg>',
    'fa-user':
        '<svg class="svg-inline--fa fa-user fa-w-14" aria-hidden="true" focusable="false" data-prefix="fas" data-icon="user" role="img" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512" data-fa-i2svg=""><path fill="currentColor" d="M224 256c70.7 0 128-57.3 128-128S294.7 0 224 0 96 57.3 96 128s57.3 128 128 128zm89.6 32h-16.7c-22.2 10.2-46.9 16-72.9 16s-50.6-5.8-72.9-16h-16.7C60.2 288 0 348.2 0 422.4V464c0 26.5 21.5 48 48 48h352c26.5 0 48-21.5 48-48v-41.6c0-74.2-60.2-134.4-134.4-134.4z"></path></svg>',
    'fa-phone-square-alt':
        '<svg class="svg-inline--fa fa-phone-square-alt fa-w-14" aria-hidden="true" focusable="false" data-prefix="fas" data-icon="phone-square-alt" role="img" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512" data-fa-i2svg=""><path fill="currentColor" d="M400 32H48A48 48 0 0 0 0 80v352a48 48 0 0 0 48 48h352a48 48 0 0 0 48-48V80a48 48 0 0 0-48-48zm-16.39 307.37l-15 65A15 15 0 0 1 354 416C194 416 64 286.29 64 126a15.7 15.7 0 0 1 11.63-14.61l65-15A18.23 18.23 0 0 1 144 96a16.27 16.27 0 0 1 13.79 9.09l30 70A17.9 17.9 0 0 1 189 181a17 17 0 0 1-5.5 11.61l-37.89 31a231.91 231.91 0 0 0 110.78 110.78l31-37.89A17 17 0 0 1 299 291a17.85 17.85 0 0 1 5.91 1.21l70 30A16.25 16.25 0 0 1 384 336a17.41 17.41 0 0 1-.39 3.37z"></path></svg>',
    'fa-map-marker-alt':
        '<svg class="svg-inline--fa fa-map-marker-alt fa-w-12" aria-hidden="true" focusable="false" data-prefix="fas" data-icon="map-marker-alt" role="img" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 384 512" data-fa-i2svg=""><path fill="currentColor" d="M172.268 501.67C26.97 291.031 0 269.413 0 192 0 85.961 85.961 0 192 0s192 85.961 192 192c0 77.413-26.97 99.031-172.268 309.67-9.535 13.774-29.93 13.773-39.464 0zM192 272c44.183 0 80-35.817 80-80s-35.817-80-80-80-80 35.817-80 80 35.817 80 80 80z"></path></svg>',
};

// Vuejs
var app = new Vue({
    el: '#app',
    data: {
        appointments: [],
        date: dayjs(),
        appointmentsLeft: [],
        appointmentsRight: [],
        search: '',
    },
    mounted: function () {
        var socket = io();

        socket.on('entry.create', (data) => {
            this.getAppointments(this.requestURL);
        });

        socket.on('entry.update', (data) => {
            this.getAppointments(this.requestURL);
        });

        socket.on('entry.delete', (data) => {
            this.getAppointments(this.requestURL);
        });

        // load booking list
        this.getAppointments(this.requestURL);

        if ($('.search-form input[name="phone"]').length) {
            var cleave = new Cleave('input[name="phone"]', {
                phone: true,
            });
        }

        if ($('#dob').length) {
            var cleave = new Cleave('#dob', {
                date: true,
                datePattern: ['d', 'm', 'Y'],
            });
        }

        if ($('#date').length) {
            $('#date').datepicker({
                dateFormat: 'dd/mm/yy',
                minDate: 0,
                maxDate: +7,
            });

            $('#date').datepicker('setDate', '0');
        }
    },
    computed: {
        requestURL: function () {
            var dateFormatted = this.date.format('YYYY-MM-DD');
            var url = `${API_URL}/appointments?_where[_or][0][status]=register&_where[_or][1][status]=start&customer_null=false&_sort=weight:ASC&date=${dateFormatted}&_limit=-1`;
            return url;
        },
        appointmentsLeftData: function () {
            return this.appointments.filter(function (appointment, index) {
                return index >= 0 && index < 7;
            });
        },
        appointmentsRightData: function () {
            return this.appointments.filter(function (appointment, index) {
                return index >= 7 && index < 14;
            });
        },
        appointmentsStart: function () {
            return this.appointments.filter(function (appointment, index) {
                return appointment.status == 'start';
            });
        },
        appointmentsNearActive: function () {
            return this.appointments.filter(function (appointment, index) {
                if (
                    (index == 0 && app.appointments[0].status == 'register') ||
                    (index == 1 &&
                        app.appointments[1] != undefined &&
                        app.appointments[1].status == 'register' &&
                        app.appointments[0].status == 'start')
                ) {
                    return true;
                }

                return false;
            });
        },
    },
    methods: {
        isNearActive: function (index) {
            if (
                (index == 0 && this.appointments[0].status == 'register') ||
                (index == 1 && this.appointments[0].status == 'start')
            ) {
                return true;
            }

            return false;
        },
        findIndex: function (id, appointments) {
            var index = -1;
            for (var i = 0; i < appointments.length; i++) {
                const appointment = appointments[i];
                if (appointment.id == id) {
                    index = i;
                    break;
                }
            }

            return index;
        },
        getAppointments: function (url) {
            axios.get(url).then(function (response) {
                var data = response.data;
                app.appointments = [];
                if (data.length) {
                    $.each(data, function (index, appointment) {
                        appointment.dateFormatted = dayjs(
                            appointment.date
                        ).format('DD/MM/YYYY');

                        appointment.timeRange = timeRange[appointment.time];

                        appointment.customer.name = appointment.customer.name.toLowerCase();

                        appointment.age = dayjs(appointment.customer.dob)
                            .fromNow(true)
                            .replace('a year', '1 tuổi')
                            .replace('years', 'tuổi')
                            .replace('year', 'tuổi')
                            .replace('days', 'ngày')
                            .replace('a month', '1 tháng')
                            .replace('months', 'tháng')
                            .replace('month', 'tháng');

                        app.appointments.push(appointment);
                    });
                }
            });
        },
        searchAppointment: function (e) {
            var phone = $('input[name="phone"]').val();

            // Add loading and disable this button
            $('#search.button').addClass('is-loading').attr('disabled', true);

            var todayFormatted = this.date.format('YYYY-MM-DD');
            var URLAllAppointmentsToday = `${API_URL}/appointments?date=${todayFormatted}&customer_null=false&_sort=weight:ASC&_limit=-1`;
            axios.get(URLAllAppointmentsToday).then(function (response) {
                var appointmentsToday = response.data;

                // Remove loading
                $('#search.button')
                    .removeClass('is-loading')
                    .removeAttr('disabled');

                var appointmentResults = appointmentsToday.filter(function (
                    appointment
                ) {
                    return appointment.customer.phone == phone;
                });

                var appointmentsAvail = appointmentsToday.filter(function (
                    appointment
                ) {
                    return appointment.status == 'register';
                });

                if (appointmentResults.length) {
                    $('.results').removeClass('is-hidden');
                    $('.results .result-content').removeClass('is-hidden');
                    $('.results .result-no').addClass('is-hidden');

                    var isTimeToExam = dayjs().isSameOrBefore(
                        dayjs().startOf('day').add(16, 'h').add(25, 'm')
                    );

                    var timeToExamText = isTimeToExam
                        ? 'Chưa tới thời gian khám bệnh'
                        : app.appointments[0].weight;

                    var html = appointmentResults.reduce(function (
                        html,
                        appointment,
                        index
                    ) {
                        var age = dayjs(appointment.customer.dob)
                            .fromNow(true)
                            .replace('a year', '1 tuổi')
                            .replace('years', 'tuổi')
                            .replace('year', 'tuổi')
                            .replace('days', 'ngày')
                            .replace('a month', '1 tháng')
                            .replace('months', 'tháng')
                            .replace('month', 'tháng');

                        var index = app.findIndex(
                            appointment.id,
                            appointmentsAvail
                        );

                        var timeToExamHtml = '';
                        switch (appointment.status) {
                            case 'finish':
                                timeToExamHtml = `<p class="has-text-success">${iconObject['fa-clock']}Bé đã khám bệnh xong. Cám ơn phụ huynh!</p>`;
                                break;
                            case 'ignore':
                                timeToExamHtml = `<p class="has-text-danger">${iconObject['fa-clock']}Bé đã bị qua lượt do không đến khám đúng giờ. Quý phụ huynh liên hệ phòng khám để được đăng ký lại.</p>`;
                                break;
                            case 'start':
                                timeToExamHtml = `<p class="has-text-warning">${iconObject['fa-clock']}Bé đang được khám bệnh.</p>`;
                                break;
                            case 'register':
                                timeToExamHtml = `<p class="time">${
                                    iconObject['fa-clock']
                                }Dự kiến thời gian khám: <span>${
                                    timeRange[appointment.time]
                                }</span>; Số thứ tự đang khám hiện tại: <span>${
                                    app.appointmentsStart.length
                                        ? app.appointmentsStart[0].weight
                                        : timeToExamText
                                }</span>; Còn <span>${index}</span> người nữa mới tới lượt của bé.</p>`;
                                break;
                        }

                        html += `
                        <div class="appointment-result column is-4">
                            <p class="stt">${iconObject['fa-sort-numeric-down']}Số thứ tự đăng ký: <span>${appointment.weight}</span></p>
                            ${timeToExamHtml}
                            <p class="name">${iconObject['fa-user']}Họ và tên: <span>${appointment.customer.name} - ${age}</span></p>
                            <p class="phone">${iconObject['fa-phone-square-alt']}Điện thoại: <span>${appointment.customer.phone}</span></p>
                            <p class="address">${iconObject['fa-map-marker-alt']}Địa chỉ: <span>${appointment.customer.address}</span></p>
                        </div>`;

                        return html;
                    },
                    '');
                    $('.results .result-content').html(html);
                } else {
                    $('.results').removeClass('is-hidden');
                    $('.results .result-content').addClass('is-hidden');
                    $('.results .result-no').removeClass('is-hidden');
                }
            });
        },
        register: function () {
            $('article.message').addClass('is-hidden');
            $('button[type="submit"]').addClass('is-loading');
            $('button[type="submit"]').attr('disabled', true);
            var data = {};

            $('form input').each(function (i, el) {
                if ($(el).attr('id') != undefined) {
                    data[$(el).attr('id')] = $(el).val();
                }
            });

            data.time = $('#time').val();

            axios
                .post('/api/register', data)
                .then(function (response) {
                    // remove disable button
                    $('button[type="submit"]').removeAttr('disabled');

                    var appointment = response.data;
                    $('button[type="submit"]').removeClass('is-loading');
                    $('html, body').animate(
                        { scrollTop: $('.hero-body').offset().top },
                        'slow'
                    );
                    // Validate data
                    if (!appointment.success) {
                        $('article.message')
                            .removeClass('is-hidden is-success')
                            .addClass('is-danger');

                        $('article.message .message-body').html(
                            appointment.message
                        );
                    } else {
                        $('article.message')
                            .removeClass('is-hidden is-danger')
                            .addClass('is-success');
                        var timeMessage = appointment.isDiffTime
                            ? `<p>Thời gian bạn chọn đã không còn chổ. Phòng khám xếp cho bạn đến khám vào: ${
                                  timeRange[appointment.data.time]
                              }</p>`
                            : `<p>Dự kiến thời gian khám cho bé là: ${
                                  timeRange[appointment.data.time]
                              }</p>`;
                        timeMessage +=
                            '<p>Phụ huynh có thể tra cứu lịch khám đã đăng ký <a href="/tra-cuu">tại đây</a></p>';
                        var successMessage = appointment.message + timeMessage;
                        $('article.message .message-body').html(successMessage);

                        $('form input').each(function (i, el) {
                            $(el).val('');
                        });

                        $('#date').datepicker('setDate', '0');
                    }
                })
                .catch(function (err) {
                    $('button[type="submit"]').removeClass('is-loading');
                    console.log(err);
                });

            console.log(data);
        },
    },
});

(function ($) {
    $(document).ready(function () {
        $('.navbar-burger').click(function () {
            // Toggle the "is-active" class on both the "navbar-burger" and the "navbar-menu"
            $('.navbar-burger').toggleClass('is-active');
            $('.navbar-menu').toggleClass('is-active');
        });
    });
})(jQuery);
